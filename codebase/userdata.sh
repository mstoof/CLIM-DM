#!/bin/bash
apt-get update
apt-get install -y python3 python3-pip
pip3 install flask authlib pymongo
mkdir templates
mkdir static
mkdir tests
mkdir codebase
cat <<EOT >> app.py
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
EOT
cd codebase
cat <<EOT >> mongodb.py
import pymongo
from pymongo import MongoClient
from datetime import datetime

# cluster = MongoClient("mongodb+srv://mstoof:CD43FC237AED@clim-db.0cedxcc.mongodb.net/?retryWrites=true&w=majority")
#
# db = cluster["DNS"]
# collection = db["user_data"]
#
# collection.insert_one({"_id":0, "email": "maurice@mcstoof.com", "token": 0, "fqdn": "test.db.com", "latest_change": 0-0})

class Database:
    def __init__(self):
        self.cluster = MongoClient("mongodb+srv://mstoof:CD43FC237AED@clim-db.0cedxcc.mongodb.net/?retryWrites=true&w=majority")
        self.db = self.cluster["DNS"]
        self.collection = self.db["user_data"]
        self.counter = 0

    def add_records(self, email, token, fqdn):
        result = self.collection.insert_one({'email': email,
                                             'token': token,
                                             'fqdn': fqdn,
                                             'date': datetime.now()
                                             })
        print(result)
        print(result.inserted_id)
        return 1

    def update_records(self, old_fqdn, fqdn):
        result = self.collection.find_one_and_update({'fqdn': old_fqdn}, {"$set": {'fqdn':  fqdn,
                                                                                   'date': datetime.now()
                                                                                    }})
        print(result)
        return result

    def delete_records(self, fqdn):
        result = self.collection.delete_one({'fqdn': fqdn})

        print(result)

        return result


if __name__ == '__main__':
    db = Database()

    # db.add_records('maurice@mcstoof.com', '1', 'dns.com', '10-10-2023')
    # db.update_records('dns.com', 'ns1.alibaba.com')
    db.delete_records('dns.com')
EOT
cd ..
cat <<EOT >> templates/auth.html
<!DOCTYPE html>
<html lang="en">
   <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Authlib Connect</title>
   </head>
   <body>
      <p align="center">
         <a href="google/">
         <img id="google"
            src="https://img.shields.io/badge/Google-Connect-brightgreen?style=for-the-badge&labelColor=black&logo=google"
            alt="Google"> <br>
         </a>
         <a href="twitter/">
         <img id="twitter"
            src="https://img.shields.io/badge/Twitter-Connect-brightgreen?style=for-the-badge&labelColor=black&logo=twitter"
            alt="Twitter"> <br>
         </a>
         <a href="facebook/">
         <img id="facebook"
            src="https://img.shields.io/badge/Facebook-Connect-brightgreen?style=for-the-badge&labelColor=black&logo=facebook"
            alt="Facebook"> <br>
         </a>
      </p>



   </body>
</html>
EOT
cat <<EOT >> templates/index.html
<!doctype html>
<html>
  <head>
    <title>CLIM - Eindopdracht Devon & Maurice</title>
  </head>
  <body>
    <h1>CLIM - Eindopdracht Devon & Maurice</h1>
    <h3>Choose one of the options below</h3>
    <p><a href="/authenticated">Add Records</a></p>
    <p><a href="/updaterecords">Update Records</a></p>
    <p><a href="/removerecords">Remove Records</a></p>

    <br>
    <h2>Add DNS records</h2>
    <form action="/addrecords" method="post">
      <label for="dns">DNS Name</label>
      <input type="text" id="dnsname" name="dnsname"><br>
      <label for="ip">IP Address:</label>
      <input type="text" id="ipaddress" name="ipaddress"><br>
      <input type="submit" value="Submit">
    </form>
  </body>
</html>
EOT
cat <<EOT >> templates/updaterecords.html
<!doctype html>
<html>
  <head>
    <title>CLIM - Eindopdracht Devon & Maurice</title>
  </head>
  <body>
    <h1>CLIM - Eindopdracht Devon & Maurice</h1>
    <h3>Choose one of the options below</h3>
    <p><a href="/authenticated">Add Records</a></p>
    <p><a href="/updaterecords">Update Records</a></p>
    <p><a href="/removerecords">Remove Records</a></p>

    <br>
    <h2>Update DNS records</h2>
    <form action="/updaterecords" method="post">
      <label for="dns">DNS Name</label>
      <input type="text" id="dnsname" name="dnsname"><br>
      <label for="ip">Old IP Address:</label>
      <input type="text" id="oldipaddress" name="oldipaddress"><br>
        <label for="ip">New IP Address:</label>
      <input type="text" id="newipaddress" name="newipaddress"><br>
      <input type="submit" value="Submit">
    </form>
  </body>
</html>
EOT
cat <<EOT >> templates/removerecords.html
<!doctype html>
<html>
  <head>
    <title>CLIM - Eindopdracht Devon & Maurice</title>
  </head>
  <body>
    <h1>CLIM - Eindopdracht Devon & Maurice</h1>
    <h3>Choose one of the options below</h3>
    <p><a href="/authenticated">Add Records</a></p>
    <p><a href="/updaterecords">Update Records</a></p>
    <p><a href="/removerecords">Remove Records</a></p>

    <br>
    <h2>Remove DNS records</h2>
    <form action="/removerecords" method="post">
      <label for="dns">DNS Name</label>
      <input type="text" id="dnsname" name="dnsname"><br>
      <input type="submit" value="Submit">
    </form>
  </body>
</html>
EOT
