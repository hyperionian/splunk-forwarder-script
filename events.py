import httplib, time

conn = httplib.HTTPSConnection("192.168.26.9", 8089)
conn.connect()
conn.putrequest("POST", "/services/receivers/stream?source=mac-osx&sourcetype=simulation_data")
conn.putheader("Authorization", "Splunk 1f0a77e462926150a001819056ed05a3")
conn.putheader("x-splunk-input-mode", "streaming")
conn.endheaders()

print "Looping..."
while True:
    conn.send("%s  sample stream events from python script .\n" % time.asctime())
    time.sleep(1)
