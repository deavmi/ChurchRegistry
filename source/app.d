import std.stdio;

import types;
import db;
import logging;

void main()
{
	DEBUG("Edit source/app.d to start your project.");

	import printer;

	BaseEntry e = new BaseEntry();
	byte[] d = generate(e);

	File f;
	f.open("test.pdf", "wb");
	f.rawWrite(d);
	f.close();

	DBConfig db = DBConfig("haram.sqlite");

	import web : WebServer;
	WebServer ws = new WebServer(db, "Catholic Church");
	ws.run();

}
