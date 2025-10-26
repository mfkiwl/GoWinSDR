import sys
from PyQt6.QtWidgets import QApplication
from main_window import MainWindow

if __name__ == "__main__":
    app = QApplication(sys.argv)

    # 在这里应用样式表 (可选, 取消注释以启用)
    # app.setStyleSheet("""
    #     QWidget {
    #         font-size: 10pt;
    #     }
    #     QPushButton {
    #         background-color: #4a69bd;
    #         color: white;
    #         border-radius: 5px;
    #         padding: 5px 10px;
    #     }
    #     QPushButton:hover {
    #         background-color: #60a3bc;
    #     }
    #     QPushButton:pressed {
    #         background-color: #3c40c6;
    #     }
    #     QPushButton:disabled {
    #         background-color: #95a5a6;
    #     }
    #     QTextEdit, QLineEdit {
    #         background-color: #ecf0f1;
    #         border: 1px solid #bdc3c7;
    #         border-radius: 5px;
    #     }
    #     QGroupBox {
    #         font-weight: bold;
    #         font-size: 11pt;
    #     }
    # """)

    window = MainWindow()
    window.show()
    sys.exit(app.exec())

