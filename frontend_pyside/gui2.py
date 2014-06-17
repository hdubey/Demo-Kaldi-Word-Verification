#!/usr/bin/env python

# Allow access to command-line arguments
import sys, os
import subprocess
import locale
 
# Import the core and GUI elements of Qt
from PySide.QtCore import *
from PySide.QtGui import *

# Import for plotting
import matplotlib
matplotlib.use('Qt4Agg')
matplotlib.rcParams['backend.qt4']='PySide'
import pylab
from matplotlib.backends.backend_qt4agg import FigureCanvasQTAgg as FigureCanvas
from matplotlib.figure import Figure
import numpy as np
import wave
 
# Create the QApplication object
qt_app = QApplication(sys.argv)

class MatplotlibWidget(FigureCanvas):
  def __init__(self, parent=None):
    super(MatplotlibWidget, self).__init__(Figure())
    self.setParent(parent)
    self.figure = Figure(figsize=(100,50), facecolor=(1,1,1), edgecolor=(0,0,0))
    self.canvas = FigureCanvas(self.figure)
    self.axes = self.figure.add_axes([0,0,1,1])
    self.axes.axis('off')

  def plot(self, recp):
    spf = wave.open('30.record/log/%s.wav' % (recp),'r')
    signal = spf.readframes(-1)
    signal = np.fromstring(signal, 'Int16')
    spf.close()
    self.axes.cla()
    self.axes.axis('off')
    self.axes.plot(signal)
 
class GUIDemo2(QWidget):
  ''' A Qt application that displays the text, "Hello, world!" '''
  def __init__(self):
    # Initialize the object as a QLabel
    QWidget.__init__(self)
    self.setMinimumSize(QSize(400, 200))
    self.setWindowTitle('Demo2!')

    # Create the QVBoxLayout that lays out the whole form
    self.layout = QVBoxLayout()
    self.form_layout = QFormLayout()

    self.recipient = QLineEdit(self)
    self.form_layout.addRow('出題區：', self.recipient)
    self.current = QLabel('', self)
    self.form_layout.addRow('目前題目：', self.current)
    self.greeting = QLabel('', self)
    self.form_layout.addRow('<font color=red size=40>分數：</font>', self.greeting)

    self.layout.addLayout(self.form_layout)

    # Figure drawing
    self.canvas = MatplotlibWidget(self)
    self.canvas.setMaximumSize(400,80)
    self.layout.addWidget(self.canvas)

    self.button_box = QHBoxLayout()
    self.button_box.addStretch(1)

    self.build_button = QPushButton('出題', self)
    self.build_button.clicked.connect(self.define_problem)
    self.button_box.addWidget(self.build_button)

    self.rec_button = QPushButton('錄音', self)
    self.rec_button.clicked.connect(self.rec_problem)
    self.button_box.addWidget(self.rec_button)

    self.eval_button = QPushButton('評分', self)
    self.eval_button.clicked.connect(self.eval_problem)
    self.button_box.addWidget(self.eval_button)

    self.layout.addLayout(self.button_box)
    self.setLayout(self.layout)

    # Set the size, alignment, and title
    
  @Slot()
  def define_problem(self):
    '''Show the selected problem'''
    recp = self.recipient.text()
    p = subprocess.Popen(
      ["zsh", "40.verification/10_gen_graph.zsh", recp],
      stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    p.wait()
    self.current.setText(self.recipient.text())
    self.greeting.setText("")

  @Slot()
  def rec_problem(self):
    '''Answer the selected problem'''
    recp = self.recipient.text()
    p = subprocess.Popen(
      ["zsh", "30.record/record_test_data.zsh", recp],
      stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    p.wait()

    self.canvas.plot(recp)
    self.canvas.draw()

    self.greeting.setText("<font color=red size=48>錄製成功，請按「評分」</font>")

  @Slot()
  def eval_problem(self):
    recp = self.recipient.text()
    p = subprocess.Popen(
      ["zsh", "40.verification/20_get_ratio.zsh", "../30.record/log/%s.wav" % (recp)],
      stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    p.wait()

    encoding = locale.getdefaultlocale()[1]
    tmpstr = p.stdout.readline().decode(encoding).strip(' \t\n\r').split(' ')
    ratio = round(float(tmpstr[2]) * 200 - 100, 2)
    self.greeting.setText("<font color=red size=48>%s</font>" % (ratio))
    
  

  def run(self):
    ''' Show the application window and start the main event loop '''
    # Make silence profile
    if not os.path.isfile("30.record/tmp/noise.prof"):
      p = subprocess.Popen(
        ["zsh", "30.record/get_noise_profile.zsh"],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE)
      p.wait()
    # Make filler graph
    if not os.path.isfile("40.verification/tmp/HCLG_filler.fst.gz"):
      p = subprocess.Popen(
        ["zsh", "40.verification/05_gen_filler.zsh"],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE)
      p.wait()
      print(p.stderr.read())

    sys.stdout.flush()
    self.show()
    qt_app.exec_()

# Create an instance of the application window and run it
app = GUIDemo2()
app.run()
