import os
import shutil
import subprocess
from flask import Flask, render_template
from flask_socketio import SocketIO, emit


app = Flask(__name__)
app.config['SECRET_KEY'] = 'secret_key'
socketio = SocketIO(app)

@app.route('/')
def index():
    return render_template('index.html')

@socketio.on('update_chrome')
def update_chrome():
    # Execute the chrome_script using subprocess
    process = subprocess.Popen(['bash', '/home/avadhoot/scripts/flask-app/update_chrome.sh'], stdout=subprocess.PIPE)
    for line in iter(process.stdout.readline, b''):
        socketio.emit('chrome_output', {'output': line.decode('utf-8').strip()})
    

    socketio.emit('chrome_output', {'output': 'Click On Download Button Below To Download '})

    

@socketio.on('update_firefox')
def update_firefox():
    # Execute the firefox_script using subprocess
    process = subprocess.Popen(['sh', '/home/avadhoot/scripts/flask-app/update_firefox.sh'], stdout=subprocess.PIPE)
    for line in iter(process.stdout.readline, b''):
        socketio.emit('firefox_output', {'output': line.decode('utf-8').strip()})


    socketio.emit('firefox_output', {'output': 'Click On Download Button Below To Download '})


@socketio.on('update_vmware')
def update_vmware():
    output_messages = []

    # Execute the shell script using subprocess
    process = subprocess.Popen(['sh', '/home/avadhoot/scripts/flask-app/update_vmware.sh'], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    
    # Capture the output of the subprocess and send updates to the client
    for line in iter(process.stdout.readline, ''):
        output_line = line.strip()
        output_messages.append(output_line)
        socketio.emit('vmware_output', {'output': output_line})

    socketio.emit('vmware_output', {'output': '$$'})

    socketio.emit('vmware_output', {'output': 'Click On Download Button Below To Download '})


@socketio.on('update_ctx')
def update_ctx(data):
    output_messages = []

    

    ica_path = data['vmwareUrl']
    usb_path = data['usbUrl']
    print("value 1 is"+""+ica_path)
    print("value 2 is "+""+usb_path)
    
    try:
        # process = subprocess.Popen(['sh','/home/avadhoot/scripts/flask-app/update_ctx.sh',ica_path,usb_path], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        process = subprocess.Popen(['/home/avadhoot/scripts/flask-app/update_ctx.sh',ica_path,usb_path], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

         # Capture the output of the subprocess and send updates to the client
        for line in iter(process.stdout.readline, ''):
             output_line = line.strip()
             output_messages.append(output_line)
             socketio.emit('ctx_output', {'output': output_line})
    
       
        socketio.emit('ctx_output', {'output': '$$'})
        socketio.emit('ctx_output', {'output': 'Click On Download Button Below To Download '})

        
    
    except subprocess.CalledProcessError as e:
        error_msg = f"Error: {e.output.decode('utf-8').strip()}"
        socketio.emit('ctx_output', {'output': error_msg})



if __name__ == '__main__':
    socketio.run(app, debug=True, host='0.0.0.0', port=5000)

