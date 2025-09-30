module db;

import ddbc;
import logging;

public struct DBConfig
{
    private string _dFilePath;

    this(string databasePath)
    {
        this._dFilePath = databasePath;
    }

    public string path()
    {
        return this._dFilePath;
    }

    public string url()
    {
        import std.string : format;
        return format("sqlite:%s", path());
    }
}


import hibernated.core;

private SessionFactory sf;

private void init(DataSource ds, SessionFactory sf)
{
    auto c = ds.getConnection();
    scope(exit)
    {
        c.close();
    }

    sf.getDBMetaData().updateDBSchema(c, false, true);
}

private SessionFactory doConnect(string ddbcURL)
{
    if(sf is null)
    {
        import types : Church2, ParentalFigure2, Baptism, Priest;
        EntityMetaData schema = new SchemaInfoImpl!(Church2, ParentalFigure2, Baptism, Priest);

        import ddbc.drivers.sqliteddbc : SQLiteDriver = SQLITEDriver;
        SQLiteDriver driver = new SQLiteDriver();
        SQLiteDialect dialect = new SQLiteDialect();
        DataSource ds = new ConnectionPoolDataSourceImpl(driver, ddbcURL, null);

        sf = new SessionFactoryImpl(schema, dialect, ds);

        // Initialize tables if they don't alrady exist
        init(ds, sf);
    }
    

    return sf;
}

public SessionFactory openDatabase(DBConfig cfg)
{
    import std.file : exists, isFile;
    DEBUG(cfg.path());
    if(exists(cfg.path()))
    {
        if(!isFile(cfg.path()))
        {
            ERROR("Please delete the path '"~cfg.path()~"' as it is not a file");
            return null;
        }

        INFO("Database '", cfg.path(),"' already exists");
    }

    return doConnect(cfg.path());

    // DEBUG("Halo");
    // auto c = createConnection(cfg.url());

    // // create db    
    // createTables0(c);
    
    // c.commit();
    // // c.close();

    // // c.


    // return c;
}

private string SQL_CHURCH_CREATE = 
`
CREATE TABLE "church" (
	"id"	INTEGER,
	"name"	INTEGER,
	"city"	TEXT,
	"province"	TEXT,
	"dateAdded"	INTEGER NOT NULL,
	PRIMARY KEY("id")
);
`;

private string SQL_PARENTAL_FIGURES_CREATE = 
`
CREATE TABLE "parental_figures" (
	"id"	INTEGER,
	"name"	TEXT NOT NULL,
	"dateAdded"	INTEGER NOT NULL,
	PRIMARY KEY("id")
)
`;

private string SQL_BAPTISMAL_PARENTS_CREATE =
`
CREATE TABLE "baptismal_parents" (
	"baptism_id"	INTEGER NOT NULL,
	"parental_id"	INTEGER NOT NULL,
	FOREIGN KEY("baptism_id") REFERENCES "baptisms"("id"),
	FOREIGN KEY("parental_id") REFERENCES "parental_figures"("id")
)
`;

private string SQL_BAPTISMS =
`
CREATE TABLE "baptisms" (
	"id"	INTEGER,
	"baptismal_name"	TEXT,
	"place_of_birth"	TEXT,
	"baptised_date"	TEXT,
	"church_id"	INTEGER,
	"dateAdded"	INTEGER NOT NULL,
	PRIMARY KEY("id"),
	CONSTRAINT "Baptism must have a church ID it links to" FOREIGN KEY("church_id") REFERENCES "church"("id")
)
`;

public void createTables0(Connection conn)
{
    auto s = conn.createStatement();
    s.executeUpdate(SQL_CHURCH_CREATE);
    s.executeUpdate(SQL_PARENTAL_FIGURES_CREATE);
    s.executeUpdate(SQL_BAPTISMAL_PARENTS_CREATE);
    s.executeUpdate(SQL_BAPTISMS);
    s.close();
}

import types;
import std.string : format;

import std.datetime.date : DateTime;
import std.datetime.systime : Clock, stdTimeToUnixTime;

public ptrdiff_t currTime()
{
    return Clock.currStdTime().stdTimeToUnixTime();
}

private string SQL_PARENTAL_FIGURE_ADD = 
`
    INSERT INTO parental_figures(name, dateAdded)
    VALUES ("%s", %d);
`;

public void addParentalFigure(Connection conn, ParentalFigure pf)
{
    auto s = conn.createStatement();

    s.executeUpdate
    (
        format(SQL_PARENTAL_FIGURE_ADD, pf.name(), currTime())
    );
    s.close();
}

private string SQL_PARENTAL_FIGURES_LIST =
`
SELECT * FROM parental_figures

ORDER BY id ASC

-- Parameterize this
%s
`;

public ParentalFigure[] listParentalFigures
(
    Connection conn,
    ptrdiff_t limit = -1,
    ptrdiff_t count = -1
)
{
    auto s = conn.createStatement();

    auto constraints = limit > -1 ? format("LIMIT %d", limit) : "";

    constraints ~= count > -1 ? format("COUNT %d", count) : "";

    auto rs = s.executeQuery
    (
        format(SQL_PARENTAL_FIGURES_LIST, constraints)
    );

    ParentalFigure[] pfs;
    while(rs.next())
    {
        ParentalFigure pf = ParentalFigure
        (
            rs.getInt("id"),
            rs.getString("name"),
            rs.getInt("dateAdded")
        );
        pfs ~= pf;
    }

    rs.close();
    s.close();
    
    DEBUG("listing parental figures returned: ", pfs);
    return pfs;
}

private string SQL_PARENTAL_FIGURE_DEL =
`
    DELETE FROM parental_figures
    WHERE id = %d
`;

public void removeParentalFigure(Connection conn, size_t pfId)
{
    auto s = conn.createStatement();
    auto i = s.executeUpdate
    (
        format(SQL_PARENTAL_FIGURE_DEL, pfId)
    );
	s.close();
	
    if(i)
    {
        DEBUG("Deleted parental figure with id: ", pfId, i);
    }
    else
    {
        ERROR("Failure to delete parental figure with id '", pfId, "'");
    }
}

private string SQL_CHURCH_GET =
`
    SELECT * FROM church
    WHERE id = %d
`;

public Church getChurch(Connection conn, size_t id)
{
    auto s = conn.createStatement();
    auto rs = s.executeQuery
    (
        format(SQL_CHURCH_GET, id)
    );

    scope(exit)
    {
        rs.close();
        s.close();
    }

    // TODO: Check here?
    rs.next();

    Church church = Church
    (
        rs.getInt("id"),
        rs.getString("name"),
        rs.getString("city"),
        rs.getString("province"),
        rs.getInt("dateAdded")
    );

    return church;
}

private string SQL_CHURCH_ADD = 
`
    INSERT INTO church(name, city, province, dateAdded)
    VALUES("%s", "%s", "%s", %d);
`;

public Priest[] getPriests(SessionFactory sf)
{
    auto s = sf.openSession();
    scope(exit)
    {
        s.close();
    }

    auto q = s.createQuery("FROM Priest");
    Priest[] ps = q.list!(Priest)();
    foreach(p; ps)
    {
        DEBUG("Found priest: ", p);
    }
    return ps;
}

public Priest getPriest(SessionFactory sf, size_t id)
{
    auto s = sf.openSession();
    scope(exit)
    {
        s.close();
    }

    auto q = s.createQuery("FROM Priest WHERE id = :ID").setParameter("ID", id);
    Priest[] ps = q.list!(Priest)();
    return ps[0];
}

public void addPriest(SessionFactory sf, Priest p)
{
    auto s = sf.openSession();
    scope(exit)
    {
        s.close();
    }

    // update time = created time
    p._dateUpdated = p._dateAdded;
    s.save(p);
}

public void updatePriest(SessionFactory sf, Priest p)
{
    auto s = sf.openSession();
    scope(exit)
    {
        s.close();
    }

    // fetch the entryAdded
    p._dateAdded = getPriest(sf, p.getId())._dateAdded;

    // update time `updateTime`
    p._dateUpdated = currTime();

    s.update(p);
}

public void removePriest(SessionFactory sf, Priest p)
{
    auto s = sf.openSession();
    scope(exit)
    {
        s.close();
    }

    s.remove(p);
}

public void removePriest(SessionFactory sf, size_t id)
{
    // construct a dummy just with `id` to match on
    auto p = new Priest();
    p.id = id;
    removePriest(sf, p);
}

public Church2[] getChurches(SessionFactory sf)
{
    auto s = sf.openSession();
    scope(exit)
    {
        s.close();
    }

    auto q = s.createQuery("FROM Church2");
    Church2[] cs = q.list!(Church2)();
    foreach(c; cs)
    {
        DEBUG("Church listing: ", c);
    }
    return cs;
}

public Church2 getChurch(SessionFactory sf, size_t id)
{
    auto s = sf.openSession();
    scope(exit)
    {
        s.close();
    }

    auto q = s.createQuery("FROM Church2 WHERE id = :ID").setParameter("ID", id);
    Church2[] cs = q.list!(Church2)();
    return cs[0];
}

public void addChurch(SessionFactory sf, Church2 c)
{
    auto s = sf.openSession();
    scope(exit)
    {
        s.close();
    }

    // update time = created time
    c._entryUpdated = c._entryAdded;
    s.save(c);
}

public void updateChurch(SessionFactory sf, Church2 c)
{
    auto s = sf.openSession();
    scope(exit)
    {
        s.close();
    }

    // fetch the entryAdded
    c._entryAdded = getChurch(sf, c.getId())._entryAdded;

    // update time `updateTime`
    c._entryUpdated = currTime();

    s.update(c);
}

public void removeChurch(SessionFactory sf, Church2 c)
{
    auto s = sf.openSession();
    scope(exit)
    {
        s.close();
    }

    s.remove(c);
}

public void removeChurch(SessionFactory sf, size_t id)
{
    // construct a dummy just with `id` to match on
    auto c = new Church2("", "", "");
    c.id = id;
    removeChurch(sf, c);
}

import types;


private string SQL_CHURCH_LIST =
`
SELECT * FROM church

ORDER BY id ASC

-- Parameterize this
%s
`;

public Church[] listChurches(Connection conn, ptrdiff_t limit = -1)
{
    auto s = conn.createStatement();
    auto rs = s.executeQuery
    (
        format(SQL_CHURCH_LIST, limit > -1 ? format("LIMIT %d", limit) : "")
    );


    Church[] churches;
    while(rs.next())
    {
        Church church = Church
        (
            rs.getInt("id"),
            rs.getString("name"),
            rs.getString("city"),
            rs.getString("province"),
            rs.getInt("dateAdded")
        );
        churches ~= church;
    }
	rs.close();
	s.close();
    
    DEBUG("listing returned: ", churches);
    return churches;
}

private string SQL_CHURCH_DEL =
`
    DELETE FROM church
    WHERE id = %d
`;

// public void removeChurch(Connection conn, size_t churchId)
// {
//     auto s = conn.createStatement();
//     auto i = s.executeUpdate
//     (
//         format(SQL_CHURCH_DEL, churchId)
//     );
//     s.close();

//     if(i)
//     {
//         DEBUG("Deleted church with id: ", churchId, i);
//     }
//     else
//     {
//         ERROR("Failure to delete church with id '", churchId, "'");
//     }
// }

private string SQL_BAPTISM_LIST =
`
SELECT * FROM baptisms

-- Parameterize this
%s
`;

public BaptismalEntry[] listBaptisms(Connection conn, ptrdiff_t limit = -1)
{
    auto s = conn.createStatement();
    auto rs = s.executeQuery
    (
        format(SQL_BAPTISM_LIST, limit > -1 ? format("LIMIT %d", limit) : "")
    );


    BaptismalEntry[] baptisms;
    while(rs.next())
    {
    	DEBUG(rs);
        BaptismalEntry baptism = new BaptismalEntry
        (
            rs.getInt("id"),
            rs.getString("baptismal_name"),
            rs.getInt("dateAdded")
        );
        baptisms ~= baptism;

        baptism.setBaptismalDate(rs.getString("baptised_date"));

        DEBUG("b_id: ", baptism.id());
        DEBUG("b_name: ", baptism.name());
    }


	rs.close();
	s.close();
    
    DEBUG("listing returned: ", baptisms);
    return baptisms;
}

/**
SELECT name FROM
	(
		SELECT * FROM baptismal_parents

		LEFT JOIN parental_figures pf
		WHERE parental_id = pf.id
	)
*/
private string SQL_DETERMINE_BAPTISMAL_FIGURES =
`
SELECT * FROM
	(
		SELECT * FROM baptismal_parents

		LEFT JOIN parental_figures pf
		WHERE parental_id = pf.id
	)

-- Parameterize the baptism_id below
WHERE baptism_id = %d
`;

public ParentalFigure[] getBaptismalFigures(Connection conn, size_t baptismId)
{
    // fetch basic information
    auto s = conn.createStatement();
    auto rs = s.executeQuery
    (
        format(SQL_DETERMINE_BAPTISMAL_FIGURES, baptismId)
    );

	ParentalFigure[] pfs;
    while(rs.next())
    {
    	DEBUG("baptism id: ", rs.getInt("baptism_id"));
   	 	ParentalFigure fig = ParentalFigure
        (
            rs.getInt("parental_id"),
            rs.getString("name"),
            rs.getInt("dateAdded")
        );
        pfs ~= fig;
    }

	rs.close();
	s.close();

    DEBUG("baptismal figures for '", baptismId, "' are: ", pfs);
    return pfs;
}

private string SQL_GET_BAPTISM =
`
SELECT * FROM baptisms

LEFT JOIN church c
WHERE church_id = c.id
AND baptisms.id = %d
`;

public BaptismalEntry getBaptism(Connection conn, size_t baptismId)
{
    // fetch basic information
    auto s = conn.createStatement();
    auto rs = s.executeQuery
    (
        format(SQL_GET_BAPTISM, baptismId)
    );

    BaptismalEntry bent;

    string bt_title;

    if(rs.next())
    {
        bt_title = rs.getString("baptismal_name");
    }
    else
    {
        // TODO: Handle erroneous case of entry not being found
    }

    rs.close();
    s.close();

    // fetch 
    // auto s = conn.createStatement();
    // auto rs = s.executeQuery
    // (
    //     format(SQL_BAPTISM_LIST, limit > -1 ? format("LIMIT %d", limit) : "")
    // );

    DEBUG("Fetched baptismal entry: ", bent);
    return bent;
}

private string SQL_BAPTISM_DEL =
`
    DELETE FROM baptisms
    WHERE id = %d
`;

public void removeBaptism(Connection conn, size_t baptismId)
{
    auto s = conn.createStatement();
    auto i = s.executeUpdate
    (
        format(SQL_BAPTISM_DEL, baptismId)
    );
    s.close();

    if(i)
    {
        DEBUG("Deleted baptism with id: ", baptismId, i);
    }
    else
    {
        ERROR("Failure to delete baptism with id '", baptismId, "'");
    }
}

private string SQL_BAPTISMAL_FIGURE_LINK =
`
    INSERT INTO baptismal_parents(baptism_id, parental_id)
    VALUES(%d, %d);
`;

private void linkParentToBaptism(Connection conn, size_t baptismId, size_t parentalFigureId)
{
    auto s = conn.createStatement();
    auto i = s.executeUpdate
    (
        format(SQL_BAPTISMAL_FIGURE_LINK, baptismId, parentalFigureId)
    );
    s.close();
    
    DEBUG("baptismId: ", baptismId);
    DEBUG("parentalFigureId: ", parentalFigureId);
}

// TODO: Add this
private string SQL_BAPTISM_ADD = 
`
	INSERT INTO baptisms (baptismal_name, place_of_birth, baptised_date, church_id, dateAdded)
	VALUES("%s", "Worcester", "1999/08/25", %d, %d)
	RETURNING id;
`;


// TODO: Add this
public void addBaptism(Connection conn, BaptismalEntry c, size_t churchId)
{
    auto s = conn.createStatement();
    DEBUG("Want to store: ", c);

    auto rs = s.executeQuery
    (
    	// todo: add the other fields
    	format(SQL_BAPTISM_ADD, c.title(), churchId, currTime())
    );

    scope(exit)
    {
        rs.close();
        s.close();
    }
    
    rs.next();
	auto baptismId = rs.getInt("id");	
	DEBUG("baptism_id after inserting: ", baptismId);

    // now link each parental figure to this baptism
    foreach(size_t pf_id; c.parentalFigureIds())
    {
        DEBUG("Linking parental figure with id '", pf_id, "' to baptism with id ", baptismId);
        linkParentToBaptism(conn, baptismId, pf_id);
    }
}

private string SQL_GET_BAPTISM_BY_NAME =
`
	SELECT id FROM baptisms
	WHERE baptismal_name = "%s";
`;

private auto getBaptismalIdByName(Connection conn, string baptismal_name)
{
	auto s = conn.createStatement();
	auto rs = s.executeQuery
	(
		format(SQL_GET_BAPTISM_BY_NAME, baptismal_name)
	);
	

	auto id = rs.getInt("id");
	DEBUG("baptismal id for ", baptismal_name, " is: ", id);

	rs.close();
	s.close();
	return id;
}

version(unittest)
{
    import std.stdio : tmpfile;

    import std.file : tempDir;
    

    import std.path : buildPath;


    


}

unittest
{
    string dbPath = buildPath(tempDir(), "test.sqlite");
    DBConfig testDB = DBConfig(dbPath);
    Connection conn = getConnection(testDB);

    scope(exit)
    {
        conn.close();
        import std.file : remove;
        remove(dbPath);
    }

    Church[] toAdd = 
    [
        Church
        (
            "Worcester Apostolic Church",
            "Worcester",
            "Western Cape"
        ),
        Church
        (
            "Goretti Apostolic Church",
            "Worcester",
            "Western Cape"
        )
    ];
    foreach(Church c; toAdd)
    {
        addChurch(conn, c);
    }

    Church[] churches = listChurches(conn);
    assert(churches.length == 2);
    assert(toAdd == churches);
    churches = listChurches(conn, 1);
    assert(churches.length == 1);
    assert(toAdd[0] == churches[0]);
}
