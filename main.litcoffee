# Visualisations of loaner data for a given book

## TODO

- Load ADHL-data into mongodb 
- visualise patronstat
- easy embedding in any page, ie. `<span class="patrongraph" data-faust="12345"></span>` ... `<script src="...patrongraph.js"></script>`

# Source code

## Definitions

We need a sample faust number for getting started, this will be removed later on, only used for testing when starting coding

    testFaust = "29243700"

## Dependencies

    if Meteor.isServer
        fs = Npm.require "fs"
        Fiber = Npm.require "fibers"


## Database
### Definition

We have a mapping from faust-numbers to klyngeid

    faustDB = new Meteor.Collection("faust") 

and the actual database of patron statistics

    statDB = new Meteor.Collection("patronstat") 

### Publishing

    if Meteor.isClient
        Meteor.subscribe "faust", testFaust

    if Meteor.isServer
        Meteor.publish "faust", (faust) ->
            klynge = faustDB.findOne {_id: faust}
            console.log klynge
            if not klynge
                []
            else
                [ (faustDB.find {_id: faust}), (statDB.find {_id: klynge.klynge}) ]

### Initialisation

    if Meteor.isServer
        dbLoading = false
        dbLoaded = 0

Make sure we only initialise the database once. Initialise it by mapping `handleLines` across each line in the file.

        initDB = ->
            return if dbLoading or statDB.findOne {_id: "dbLoaded"} 
            dbLoading = true

            foreachLineInFile "uid-bib-_-_-id-lid-klynge-dato-klyngelaan.db", handleLine, ->
                (Fiber ->
                    statDB.insert {_id: "dbLoaded"}
                    console.log "db loaded"
                    dbLoading = false
                ).run()

Parse/handle each line in the data dump

        handleLine = (line, done) -> (Fiber ->
                return if not line
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

## Client

    if Meteor.isClient
        Deps.autorun ->
            console.log (faustDB.findOne testFaust)?.klynge
            for elem in document.getElementsByClassName "patronGraph"
                faust = elem.dataset.faust
                klynge = (faustDB.findOne {_id: faust})?.klynge
                if klynge
                    statEntry = statDB.findOne {_id: klynge}
                    console.log statEntry
                    stat = {k:[], m:[]}
                    for key, val of statEntry
                        sex = key[0]
                        age = +key.slice(1)
                        if key isnt "_id"
                            console.log sex, age
                            stat[sex][age] = val

                    renderStat elem, stat


        renderStat = (elem, stat) ->
            console.log stat
            elem.innerHTML = stat




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
                done()
