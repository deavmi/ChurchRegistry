module web;

import vibe.vibe;

private DBConfig db_Cfg;

private string INSTANCE_NAME = "Our church";

import logging;
import std.conv : to;

public struct PageActivationInfo
{
    private string iName;
    private string pgName;
    public bool isHome;
    public bool isParents;
    public bool isChurches;
    public bool isBaptism;
    public bool isPriests;

    this(string instanceName, string pageName)
    {
        this.iName = instanceName;
        this.pgName = pageName;
    }
    
    public string name()
    {
        return this.pgName;
    }

    public string instance()
    {
        return this.iName;
    }
}



import db;

public final class WebServer
{
    private string instanceName;
    // private DBConfig dbCfg;

    import ddbc : Connection;
    import hibernated.core : SessionFactory;
    private SessionFactory sf;
    
    import types;

    this(DBConfig dbCfg, string instanceName)
    {
        this.instanceName = instanceName;
        // this.dbCfg = dbCfg;
        this.sf = openDatabase(dbCfg);

        // FIXME: Disable the below when done testing
        
        // addChurch(conn, Church("ffgd", "fdfd", "fddf"));
        // addChurch(conn, Church("ffgd", "fdfd", "fddf"));
    }

    private PageActivationInfo pgInfoFor(string pageName)
    {
        return PageActivationInfo(this.instanceName, pageName);
    }

    public void run()
    {
        URLRouter r = new URLRouter();
        r.get("/", &root);

        // Routes for church management
        r.get("/churches", &church);
        r.post("/doChurchAdd", &doChurchAdd);
        r.post("/doChurchEdit", &doChurchEdit);

        // Routes for priest management
        r.get("/priests", &priestManagement);
        r.post("/doPriestAdd", &doPriestAdd);
        r.post("/doPriestEdit", &doPriestEdit);
        
        // Routes for parental figure management
        r.get("/parents", &parents);
        r.get("/add_parental_figure", &add_parental_figure);
        r.post("/doParentalFigureAdd", &doParentalFigureAdd);
        
        // Routes for baptismal management
        r.get("/baptisms", &baptisms);
        r.post("/doBaptismAdd", &doBaptismAdd);
        // r.post("/doBaptismEdit", &doBaptismEdit);

        r.get("*", serveStaticFiles("./public/"));

        HTTPServerSettings cfg = new HTTPServerSettings();
        cfg.port = 8080; // TODO: Set to random port and open browser on that

        listenHTTP(cfg, r);

        runApplication();
    }

    private void priestManagement(HTTPServerRequest req, HTTPServerResponse resp)
    {
        PageActivationInfo pgInfo = pgInfoFor("Priests");
        pgInfo.isPriests = true;

        auto q = req.query;
        string* action_ptr = "action" in q;
        string action = "list";
        
        // if not specified then assume listing
        // otheriwse dtermine it here
        if(action_ptr !is null)
        {
            action = *action_ptr;
        }

        DEBUG("Action: ", action);

        // Set only when in editing mode
        // or deleting mode
        size_t priestID;

        // if mode is "remove" then,
        // lookup entry, try delete it
        // and return to listing
        if(action == "remove")
        {
            priestID = to!(size_t)(q["id"]);
            auto p = new Priest();
            p.id = priestID;
            db.removePriest(this.sf, p);
            resp.redirect("/priests");
        }
        // in editing mode, grab id
        else if(action == "edit")
        {
            priestID = to!(size_t)(q["id"]);
        }

        auto mode = action;
        auto sf = this.sf;
        resp.render!("priests.dt", pgInfo, action, priestID, mode, sf);
    }

    private void doPriestAdd(HTTPServerRequest req, HTTPServerResponse resp)
    {
        auto f_data = req.form();
        DEBUG(f_data);

        Priest p = new Priest(f_data["priestName"], f_data["priestAddress"]);
        db.addPriest(this.sf, p);
        resp.redirect("/priests?action=list");
    }

    private void doPriestEdit(HTTPServerRequest req, HTTPServerResponse resp)
    {
        auto q = req.query;
        auto f_data = req.form();
        DEBUG(f_data);

        // TODO: Place all of this into `updateChurch`
        size_t targetId = to!(size_t)(q["id"]); // id to update

        Priest p = new Priest(f_data["priestName"], f_data["priestAddress"]);
        p.id = targetId;
        db.updatePriest(this.sf, p);
        resp.redirect("/priests?action=list");
    }

    private void root(HTTPServerRequest req, HTTPServerResponse resp)
    {
        Connection conn = null;
        PageActivationInfo pgInfo = pgInfoFor("Home");
        pgInfo.isHome = true;

        // TODO: Add stuff here

        
        resp.render!("home.dt", pgInfo, conn);
    }

    private void church(HTTPServerRequest req, HTTPServerResponse resp)
    {
        Connection conn = null;
        PageActivationInfo pgInfo = pgInfoFor("Churches");
        pgInfo.isChurches = true;


        auto q = req.query;
        string* action_ptr = "action" in q;
        string action = "list";
        
        // if not specified then assume listing
        // otheriwse dtermine it here
        if(action_ptr !is null)
        {
            action = *action_ptr;
        }

        DEBUG("Action: ", action);

        // Set only when in editing mode
        // or deleting mode
        size_t churchID;

        // if mode is "remove" then,
        // lookup entry, try delete it
        // and return to listing
        if(action == "remove")
        {
            churchID = to!(size_t)(q["id"]);
            auto c = new Church2();
            c.id = churchID;
            db.removeChurch(this.sf, c);
            resp.redirect("/churches");
        }
        // in editing mode, grab id
        else if(action == "edit")
        {
            churchID = to!(size_t)(q["id"]);
        }

        auto mode = action;
        auto sf = this.sf;
        resp.render!("churches.dt", pgInfo, action, churchID, mode, sf);
    }

    private void doChurchAdd(HTTPServerRequest req, HTTPServerResponse resp)
    {
        auto f_data = req.form();
        DEBUG(f_data);

        Church2 c = new Church2(f_data["churchName"], f_data["churchAddress"], f_data["churchProvince"]);
        db.addChurch(this.sf, c);
        resp.redirect("/churches");
    }

    private void doChurchEdit(HTTPServerRequest req, HTTPServerResponse resp)
    {
        auto q = req.query;
        auto f_data = req.form();
        DEBUG(f_data);

        // TODO: Place all of this into `updateChurch`
        size_t targetId = to!(size_t)(q["id"]); // id to update

        Church2 c = new Church2(f_data["churchName"], f_data["churchAddress"], f_data["churchProvince"]);
        c.id = targetId;
        db.updateChurch(this.sf, c);
        resp.redirect("/churches");
    }

    private void parents(HTTPServerRequest req, HTTPServerResponse resp)
    {
        Connection conn = null;
        PageActivationInfo pgInfo = pgInfoFor("Parents");
        pgInfo.isParents = true;

        auto q = req.query;
        DEBUG("Query params: ", q);

        auto pot_action = "action" in q;

        if(pot_action)
        {
            if(*pot_action == "remove")
            {
                auto pot_id = "id" in q;
                size_t entry_id = to!(size_t)(*pot_id);
                WARN("Removing entry '", entry_id, "'");
                removeParentalFigure(null, entry_id);
                resp.redirect("/parents");
            }
        }

        ptrdiff_t count, limit;
        auto count_param = ("count" in q);
        auto limit_param = ("limit" in q);

        count = count_param ? to!(ptrdiff_t)(*count_param) : -1;
        limit = limit_param ? to!(ptrdiff_t)(*limit_param) : -1;

        resp.render!("parents.dt", pgInfo, conn, count, limit);
    }

    private void doParentalFigureAdd(HTTPServerRequest req, HTTPServerResponse resp)
    {
        auto f_data = req.form();
        DEBUG(f_data);

        ParentalFigure pf = ParentalFigure(f_data["parentName"]);
        addParentalFigure(null, pf);
        resp.redirect("/parents");
    }

    private void add_parental_figure(HTTPServerRequest req, HTTPServerResponse resp)
    {
        Connection conn = null;
        PageActivationInfo pgInfo = pgInfoFor("Parents");
        pgInfo.isChurches = true;

        resp.render!("add_parental_figure.dt", pgInfo, conn);
    }

    private void baptisms(HTTPServerRequest req, HTTPServerResponse resp)
    {
        Connection conn = null;
        PageActivationInfo pgInfo = pgInfoFor("Baptisms");
        pgInfo.isBaptism = true;

        auto q = req.query;
        string* action_ptr = "action" in q;
        string action = "list";
        
        // if not specified then assume listing
        // otheriwse dtermine it here
        if(action_ptr !is null)
        {
            action = *action_ptr;
        }

        DEBUG("Action: ", action);

        // Set only when in editing mode
        // or deleting mode
        size_t baptismID;

        // if mode is "remove" then,
        // lookup entry, try delete it
        // and return to listing
        if(action == "remove")
        {
            baptismID = to!(size_t)(q["id"]);
            auto b = new Baptism();
            b.id = baptismID;
            db.removeBaptism(this.sf, b);
            resp.redirect("/baptisms");
        }
        // in editing mode, grab id
        else if(action == "edit")
        {
            baptismID = to!(size_t)(q["id"]);
        }

        auto mode = action;
        auto sf = this.sf;
        resp.render!("baptisms.dt", pgInfo, action, baptismID, mode, sf);
    }

    private void doBaptismAdd(HTTPServerRequest req, HTTPServerResponse resp)
    {
        auto f_data = req.form();
        DEBUG(f_data);

        size_t[] parentalFigureIds;

        string parentalFigureFather = f_data["parentalFigureFather"];
        if(parentalFigureFather != "None")
        {
            parentalFigureIds ~= to!(size_t)(parentalFigureFather);
        }
        string parentalFigureMother = f_data["parentalFigureMother"];
        if(parentalFigureMother != "None")
        {
            parentalFigureIds ~= to!(size_t)(parentalFigureMother);
        }

        size_t churchId = to!(size_t)(f_data["churchId"]);

        // TODO: Implement this
        BaptismalEntry be = new BaptismalEntry
        (
            f_data["baptismalTitle"],
            parentalFigureIds
        );
        addBaptism(null, be, churchId);
        resp.redirect("/baptisms");
    }

    private void viewBaptism(HTTPServerRequest req, HTTPServerResponse resp)
    {
        Connection conn = null;
        PageActivationInfo pgInfo = pgInfoFor("Baptisms");
        pgInfo.isBaptism = true;

        auto q = req.query;
        DEBUG("Query params: ", q);

        size_t baptismalId = to!(size_t)(q["baptismId"]);
        

        BaptismalEntry entry = getBaptism(conn, baptismalId);

        resp.render!("view_baptism.dt", pgInfo, conn, entry);
    }
}
