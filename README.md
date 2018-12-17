# JumpCloud
QA test - Reed H

Bug 1

Job Identifier - Not immediately returned.

sevirity : low/moderate

cc: head of engineering, pm, self

OS: Ubuntu

Version : 0c3d817

Reproduce:

Send a Post request with a password to the /hash api.

Expected Result:

A job number is returned immediately and the storing and hashing of the password occurs after five seconds.

Actual Result:

The job number is returned after five seconds has passed.

Attached:

video of the issue. (would attach small clip of the behavior as seen in terminal)

---

Bug 2

Graceful shutdown - not graceful.

sevirity : high

cc: head of engineering, pm, self

OS: Ubuntu

Version : 0c3d817

Reproduce:

Send a Post request with a password to the /hash api followed immediately by a shutdown request. You can use the shell script attached to reproduce the conditions.

Expected Result:

The password hashing completes and the shutdown follows after.

Actual Result:

The shutdown command interrupts the inflight hashing and shuts down the server.

Attached:

video of the issue. (would attach small clip of the behavior as seen in terminal)
killafterpost.sh : script  used for testing.

---

Bug 3

stats api - time not returned in miliseconds.

sevirity : low/moderate

cc: head of engineering, pm, self

OS: Ubuntu

Version : 0c3d817

Reproduce:

- Send a Post request with a password to the /hash api.
- Send a Get request to the /stats api.

Expected Result:

The returned JSON would display the average time of requests to the server in miliseconds.

Actual Result:

The results returned are off by at least a factor of 10. 

Attached:

video of the issue. (would attach small clip of the behavior as seen in terminal)

Notes:
```
{"TotalRequests":100,"AverageTime":70463}
```
This request returned in under a second, but by conversion shows it taking roughly 70 seconds. (can verify using postman)

---

Bug 4

Job requests processed after shutdown.

sevirity : moderate/high

cc: head of engineering, pm, self

OS: Ubuntu

Version : 0c3d817

Reproduce:

- Send a shutdown request to the /hash api.
- Send a Post request with a password to the /hash api.
- The script attached can be used to simulate this issue.

Expected Result:

The Post request will fail as the shutdown process is pending.

Actual Result:

A job number is returned.

Attached:

video of the issue. (would attach small clip of the behavior as seen in terminal)
afterkill.sh : script used for testing.

---

Bug 5

Stats api counter - not returning accurate count.

sevirity : moderate

cc: head of engineering, pm, self

OS: Ubuntu

Version : 0c3d817

Will need to discuss with the Engineering and requirements team. It's unclear by the business requirements whether all api requests (post and get) to /hash should increment the counter or if only one of those should be used.

Reproduce:

Send a Post request with a password to the /hash api.
Send a Get request with the previous password job number to the /hash api.
Send a Get request to the /stats api.

Expected Result:

The counter should display two requests, one for the Post and one for the Get.

Actual Result:

The counter only displays one entry.

Attached:

video of the issue. (would attach small clip of the behavior as seen in terminal)


---

Test Cases (built for linux)

TC 01
Starting the password hashing application and verifying connection on a desired port.

We want to verify that the application (which will be runing locally) is open to accept connections on the desired port. Only the port chosen during the setup process should be open.

- Grab the latest build from the $internal_location.
- Set the port environment. $ export PORT=8088
- Run the application in a terminal. $ ./broken-hashserve_linux &
- Scan for the server. $ nmap -p- 127.0.0.1

* - You can also verify the application is accepting requests by sending a curl request to the /stats api.
* - $ curl  http://127.0.0.1:8088/stats

Expected Results:

You should see that the port selected is open and the application is able to accept http requests.

Sample output

```
Nmap scan report for localhost (127.0.0.1)
Host is up (0.0000070s latency).
Not shown: 65534 closed ports
PORT     STATE SERVICE
8088/tcp open  radan-http
```
* Expected Results:

```
{"TotalRequests":0,"AverageTime":0}
```
---

TC 02
Verify sending a password to the /hash api is working as intended.

A Post request to the /hash api should immediately return a job identifier. It should take a json formatted password and hash the value using SHA512. The server should be running while testing.

- Send a Post to /hash. $ curl -X POST -H "application/json" -d '{"password":"angrymonkey"}' &

Expected Results:

A job identifier is returned immediately. We will verify the hashing was successfull in another test. After five seconds has passed the password should be available for viewing through a Get request to the /hash api.

The /stats api counter should be incremented by 1.

---

TC 03
Verify a Get to the /hash api with a job number returns a base64 encoded SHA512 hash of the password. This will be an extension from the previous test.

- Send a Get to /hash including the job identifier. $ curl -H "application/json"  http://127.0.0.1:8088/hash/1

Expected Results:

A base64 encoded value of the SHA512'd password should be returned.

```
zHkbvZDdwYYiDnwtDdv/FIWvcy1sKCb7qi7Nu8Q8Cd/MqjQeyCI0pWKDGp74A1g==
```
We should check to verify that this calculation was done correctly.

...Steps here... *Note: I believe the base64 encoding was done using the binary output of the SHA512 calculation. I recall I was able to reproduce this once during some poking around, but I can't seem to reproduce the steps as I write this out. I would most likely confer with an Engineer to make sure we are doing this correctly.

We can check this with the following command:

```
echo -n angrymonkey | openssl dgst -binary -sha512 | openssl base64
```

The output generated here should match what is returned by the Get api request. (it doesn't)

---

TC 04
Verify a Get to /stats returns the correct information.

The stats return value should be a JSON data structure. The total number of api requests to /hash and the average time of a request should be displayed in miliseconds. This will be an extension from the previous test.

- Send a Get to the /stats api. $ curl http://127.0.0.1:8088/stats

Expected Results:
The returned data will look as follows:

```
{"TotalRequests":1,"AverageTime":266835}
```

---

TC 05

Verify the the software can handle multiple asychronus requests. *Note, would want to discuss with Eng / Req team about total # of requests that the application should be able to handle at a given time.

The application should be able to handle many requests at the same time.

- Run the attached script (loop.sh) to assist with this test.

Expected Results:

The application should handle all job requests sent. We can verify this by checking the returned password value for any of the 100 passwords sent to the server.

Attachments
- loop.sh

---

TC 06

Graceful shutdown of the application.

The application shutdown gracefully. It should finish any in-flight password hashing job and disallow any further requests once the shutdown process has started.

- Run the attached script (graceful.sh)

Expected Results:

- The inflight password will complete.
- The shutdown process will start and respond with a 200. (verified with Postman)
- The second password hashing request will be refused.

Attachments
- graceful.sh

----

Notes:

This was a really fun exercise! I played around with a hundful of different tools (postman, Advance Rest Client addon, and a few others) in order to poke, prod, and verify results. The TC's are potentially missing a few points, but I generally ask for input from multiple members of the team to ensure I'm writing robust cases for the things I'm testing. I am a bit dissapointed I wasn't able to verify the password hash was working correclty.. this might be a bug that I missed. I will continue poking it for my own amusement later this week.

Other items that I would ask for clarification on include the proper display of the /stats return. I wasn't entirely sure what it should be displaying. I interpreted the api "requests" as both the POST and GET hits and also just the total number of password hash's being returned (a GET to /hash/$jobNumber would increment the counter by 1).

I would also want to discuss how many connections / jobs should be able to run at any time against the application. I simulated 100 new password jobs in a script, but I imagine it could easily go into the thousands depending on the specs. I've been reading into JMeter and it's capabilities to assist with proper load/stress testing, but due to time constraints I wasn't able to fully explore that avenue. From what I've read about the tool it appears easy to get acquainted with.

An item I left out was returning human readable errors. Sending a Get to /hash with a job identifier larger than (a number I haven't verified yet) returns `strconv.Atoi: parsing "xxxxxxx..": value out of range`. I usually like to have a bit more human legible errors displayed to the end user, but that isn't a major concern.

I also almost always include a small video snippet of the issue that's found. I've been traveling heavily this past week and haven't found a fast solution for video editing on this Ubuntu install, on my OSX machines I'll make small quicktime movie clips as they generally small in size and help faciliate the reproduction steps.

The severity values I assigned are.. kinda(?) arbitrary. I generally set the severity value according to a small set of rules based on the application. This is most likely a bit different at JC than my current job so I used my best judgement based on how an issue would affect the end-user. Generally speaking any breaking bug or issue found in a new feature would get the 'blocker' status, but it's all dependent on different departmental needs (getting slightly buggy products out fast and fixing the minor issues a bit later down the road).

I appreciate the opportunity to play around with your program and the time it will take to read this wall of text. I'd be more than happy to discuss processes, tools, and general thoughts on a call or in person later this week if you have any further questions.
