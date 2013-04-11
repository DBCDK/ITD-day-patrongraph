import pymongo

db = pymongo.Connection(host='127.0.0.1', port=3002).meteor

count = 0
for line in file("uid-bib-_-_-id-lid-klynge-dato-klyngelaan.db"):
    fields = line.split()
    sex = fields[2]
    birthYear = int(fields[3][0:4])
    loanYear = int(fields[7][0:4])
    faust = fields[5]
    klynge = fields[6]
    age = loanYear - birthYear

    db.faust.update({"_id": faust}, {"_id": faust, "klynge": klynge}, upsert=True)

    db.patronstat.update({"_id": klynge}, {"$inc": {sex + str(age): 1}}, upsert=True)
    if count % 1000 is 0:
        print count
    count = count + 1
