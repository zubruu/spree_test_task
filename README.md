# README

Project use delayed_jobs for processing uploaded file without freezing whole app. For demonstration purposes there are only 2 rows each delayed_job before it will create new delayed_job. It allows to different delayed_jobs run simultaneously without freezing delayed_job processes for only one import or job kind.

There is basic view to upload file at page http://localhost:3000/imports/new.
To start delayed_job processing use command: rails jobs:work in main project folder.

The import allows to add new products, and their variants with options. Option columns must be named with prefix and option name for example: option_color

I added basic tests using minitests.