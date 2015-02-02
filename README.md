OpenRateSimple<br>
==============
<br>
OpenRate Simple Example. The simplest non-trivial OpenRate application.<br>
<br>
Compatible with OpenRate 1.5.2.2 or later.<br>
<br>
Building<br>
========<br>
<br>
You might have to build and install the OpenRate core application before you<br>
build this. Look at the Maven output and you will see something like this:<br>
<br>
      [INFO] ------------------------------------------------------------------------<br>
      [ERROR] BUILD ERROR<br>
      [INFO] ------------------------------------------------------------------------<br>
      [INFO] Failed to resolve artifact.<br>
      <br>
      Missing:<br>
      ----------<br>
      1) OpenRate:OpenRate:jar:1.5.2.2<br>
      <br>
If this is the case, clone the main OpenRate framework repository and clean and<br>
install it.<br>
<br>
<br>
Once you have the OpenRate dependency, you can build and install the application:<br>
<br>
mvn clean install<br>
<br>
<br>
Running<br>
=======<br>
<br>
You can execute the project with:<br>
<br>
mvn exec:java &<br>
<br>
You should see the message that the framework is running.<br>
<br>
Now you can give the application some data to eat.<br>
<br>
cd Data/Simple/<br>
gunzip testpipeline_simple_11.edr.gz<br>
<br>
After a few seconds you should see a ".dump" file and an ".out" file created.<br>
<br>
<br>
Shutting down<br>
=============<br>
<br>
OpenRate has a full telnet console. The easiest way of shutting down is to log<br>
into the console and issue the command:
<br>
telenet localhost 8086<br>
<br>
openrate> Framework:shutdown=true<br>
<br>