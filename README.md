# Visualisations of loaner data for a given book

## TODO

- Load ADHL-data into mongodb 
- visualise patronstat
- easy embedding in any page, ie. `<span class="patrongraph" data-faust="12345"></span>` ... `<script src="...patrongraph.js"></script>`

# Source code

## Definitions

We need a sample faust number for getting started, this will be removed later on, only used for testing when starting coding

    testFaust = "29243700"

## MongoDB databases and publishing

We have a mapping from faust-numbers to klyngeid

    faustDB = new Meteor.Collection("faust") 

and the actual database of patron statistics

    statDB = new Meteor.Collection("patronstat") 


## Dependencies

    if Meteor.isServer
        fs = Npm.require "fs"
        Fiber = Npm.require "fibers"


## Initialise database

    if Meteor.isServer
        dbLoading = false
        dbLoaded = 0

Make sure we only initialise the database once. Initialise it by mapping `handleLines` across each line in the file.

        initDB = ->
            return if dbLoading or statDB.findOne {_id: "dbLoaded"} 
            dbLoading = true

            foreachLineInFile "uid-bib-_-_-id-lid-klynge-dato-klyngelaan.db", handleLine, ->
                statDB.insert {_id: "dbLoaded"}
                dbLoading = false

Parse/handle each line in the data dump

        handleLine = (line, done) -> (Fiber ->
                fields = line.split(/\s+/)
                sex = fields[2]
                birthYear = +fields[3].slice(0,4)
                loanYear= +fields[7].slice(0,4)
                faust = fields[5]
                klynge = fields[6]
                age = loanYear - birthYear
    
                faustDB.update {_id: faust}, {_id: faust, klynge: klynge}, {upsert: true}
    
                dbOperator = {$inc: {}}
                dbOperator.$inc[sex + age] = 1
                statDB.update {_id: klynge}, dbOperator, {upsert: true}
                if ++dbLoaded % 1000 is 0
                    console.log dbLoaded, new Date()

            ).run()


Init database on startup

        Meteor.startup initDB

## Utility functions

    if Meteor.isServer
        foreachLineInFile = (filename, fn, done) ->
            stream = fs.createReadStream filename
            readbuf = ""
            stream.on "data", (data) ->
                readbuf += data
                lines = readbuf.split /\n/
                (lines.slice 0, -1).forEach fn
                readbuf = lines[lines.length - 1]
            stream.on "end", () ->
                fn readbuf if readbuf
                fn undefined
