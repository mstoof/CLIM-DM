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

