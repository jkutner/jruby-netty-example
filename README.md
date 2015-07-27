# JRuby Netty 4.x example

Demonstrates a simple HTTP handler with Netty and JRuby

To run it:

```
$ jruby -S gem install jbundler
$ jruby -S jbundle install
$ jruby server.rb
```

## Deploy to Heroku

Make sure you have the [Heroku toolbelt](http://toolbelt.heroku.com)
installed, then run:

```
$ heroku create
$ git push heroku master
```
