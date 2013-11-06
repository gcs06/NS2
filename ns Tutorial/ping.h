/*
* File: Header File for a new 'Ping' Agent class for the ns network simulator
* Credit: http://www.isi.edu/nsnam/ns/tutorial/nsnew.html
*/
#ifndef ns_ping_h
#define ns_ping_h

#include "agent.h"
#include "tclcl.h"
#include "packet.h"
#include "address.h"
#include "ip.h"

struct hdr_ping 
{
	char ret;
	double send_time;
};

class CPingAgent : public Agent 
{
	public:
		CPingAgent();
		int command(int argc, const char*const* argv);
		void recv(Packet*, Handler*);

	protected:
		int off_ping_;
};

#endif /* ns_ping_h */