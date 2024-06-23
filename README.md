# Dataware House for Healthcare Center
<br />

<p style="font-size: 36px; font-weight: 600;">What's inside?</p>
<ul>
    <li>Python Script for making random data</li>
    <li>Sql code that fill the dataware house(ETL)</li>
    <li>Docker compose for creating sql server container(Optional if you already have it)</li>
</ul>
<br />


<p style="font-size: 36px; font-weight: 600;">How to run?</p>
<ol>
    <li>First you should run the docker compose(make sure docker is installed)</li>
    <li>Then you should run the python script to generate a sql code for filling source databse(it tries to be random)</li>
    <li>After running python script you should connect a database client it can be either sql server management studio or other clients i.e Datagrip or just connect to databse via code(you have to install the sql server driver if you are willing to use code)</li>
    <li>You should run sql files in this order: setup.sql, source.sql, data.sql, staging.sql, dataware_house.sql</li>
    <li>The process takes very long time about 3-4 hours because the there are many records(millions) and the process scans the records partially each time to avoid lack of memory</li>
</ol>

~~~You can set the python code to generate less records to make the process faster~~~
