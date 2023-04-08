import json
import os
from flask import Flask, render_template, request, redirect, url_for
from authlib.integrations.flask_client import OAuth
from codebase.mongodb import Database


app = Flask(__name__)
app.secret_key = os.environ.get("SECRET_KEY") or os.urandom(24)
db = Database()

oauth = OAuth(app)
google_api_key = 'AIzaSyAXDFQx5Vp65u9q9v4nz3YqEd6zVGVZRe8'

google_client_id = '952155663284-ai3f84e5u5g2m5emq5o75noa7jcpvl3m.apps.googleusercontent.com'
google_client_secret = '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'
google_discovery_url = (
    "https://accounts.google.com/.well-known/openid-configuration"
)

@app.route('/')
def index():
    return render_template('auth.html')

@app.route('/google/')
def google():
    conf_url = 'https://accounts.google.com/.well-known/openid-configuration'
    oauth.register(
        name='google',
        client_id= google_client_id,
        client_secret= google_client_secret,
        server_metadata_url= conf_url,
        client_kwargs={
            'scope': 'openid email profile'
        }
    )

    # Redirect to google_auth function
    redirect_uri = url_for('google_auth', _external=True)
    # print(redirect_uri)
    return oauth.google.authorize_redirect(redirect_uri)

@app.route('/google/auth/')
def google_auth():
    token = oauth.google.authorize_access_token()
    print(token)
    global user
    user = oauth.google.parse_id_token(token, nonce=token["userinfo"]["nonce"])

    print(" Google User ", user)
    return redirect('/authenticated')

@app.route('/authenticated/')
def authenticated():
    return render_template('index.html')

@app.route('/addrecords', methods=['POST'])
def submit():
    print(user)
    name = request.form['dnsname']
    ipaddr = request.form['ipaddress']
    db.add_records(user["email"], user["nonce"], name)
    return f'Thank you for submitting your information, {name} ({ipaddr})!'

@app.route('/updaterecords', methods=['GET', 'POST'])
def update():
    if request.method == 'GET':
        return render_template('updaterecords.html')
    else:
        name = request.form['dnsname']
        ipaddr = request.form['newipaddress']
        db.update_records(name, name)
        return f'Thank you for submitting your information, {name}, {ipaddr})!'

@app.route('/removerecords', methods=['GET', 'POST'])
def remove():
    if request.method == 'GET':
        return render_template('removerecords.html')
    else:
        name = request.form['dnsname']
        db.delete_records(name)
        return f'Thank you for submitting your information, {name}!'


if __name__ == '__main__':
    app.run(ssl_context="adhoc", debug=True)