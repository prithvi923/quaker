quaker
======

OpenGov's Backend Project

Requirements
--------------------

+ ruby v1.9.3 or later
+ MySQL v14.14
+ Redis v2.6.16

Installation
----------------
To get started clone this repository

```
git clone git@github.com:prithvi923/quaker.git
```

Then cd into it

```
cd quaker
```

Install all the gems

```
bundle install
```

Before running the app, the following needs to be setup and running:

+ MySQL server with a database 'quaker' already created
+ Redis server running on port 6379

For the MySQL server, change the credentials to access the database in quaker.rb

Now, you're ready to run the demo locally!

```
bundle exec rackup -p 8000 config.ru
```

Visit <a>http://localhost:8000/quakes</a>!

Demo
--------
There is also a live demo of this app at <a>http://myquaker.herokuapp.com/quakes</a>