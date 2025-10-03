module types;

import std.datetime.date : DateTime, Date;

public struct RegistryInfo
{
    private DateTime _d;

    this(DateTime date)
    {
        this._d = date;
    }

    public DateTime date()
    {
        return this._d;
    }
}

public class BaseEntry
{
    private string name;
    private RegistryInfo regInfo;

    this()
    {

    }

    
}

public struct Church
{
    private string _n, _c, _p;
    private size_t _id;
    private ptrdiff_t _da;

    this
    (
        size_t id,
        string name,
        string city,
        string province,
        ptrdiff_t dateAdded
    )
    {
        this._id = id;
        this._n = name;
        this._c = city;
        this._p = province;
        this._da = dateAdded;
    }

    this
    (
        string name,
        string city,
        string province
    )
    {
        this(0, name, city, province, 0);
    }

    public string name()
    {
        return this._n;
    }

    public string city()
    {
        return this._c;
    }

    public string province()
    {
        return this._p;
    }

    public size_t id()
    {
        return this._id;
    }

    public string dateAdded()
    {
        import std.datetime.systime;
        SysTime d = SysTime.fromUnixTime(this._da);
        return d.toSimpleString();
    }
}

public struct ParentalFigure
{
    private string _n;
    private size_t _id;
    private ptrdiff_t _da;

    this
    (
        size_t id,
        string name,
        ptrdiff_t dateAdded
    )
    {
        this._id = id;
        this._n = name;
        this._da = dateAdded;
    }

    this
    (
        string name
    )
    {
        this(0, name, 0);
    }

    public string name()
    {
        return this._n;
    }

    public size_t id()
    {
        return this._id;
    }

    public string dateAdded()
    {
        import std.datetime.systime;
        SysTime d = SysTime.fromUnixTime(this._da);
        return d.toSimpleString();
    }
}

import utils;

@Table("churches")
public class Church2
{
    // @Id
    public size_t id;
    public string _name;
    public string _city;
    public string _province;
    public size_t _entryAdded, _entryUpdated;

    this()
    {

    }

    this(string name, string city, string province)
    {
        this._name = name;
        this._city = city;
        this._province = province;
        this._entryAdded = currTime();
    }

    public string name()
    {
        return this._name;
    }

    public size_t getId()
    {
        return this.id;
    }

    public string city()
    {
        return this._city;
    }

    public string province()
    {
        return this._province;
    }

    public string dateAdded()
    {
        import std.datetime.systime;
        SysTime d = SysTime.fromUnixTime(this._entryAdded);
        return d.toSimpleString();
    }

    public string dateUpdated()
    {
        import std.datetime.systime;
        SysTime d = SysTime.fromUnixTime(this._entryUpdated);
        return d.toSimpleString();
    }
}

@Table("parental_figures")
public class ParentalFigure2
{
    size_t id;
    string _name;
    @ManyToMany
    Baptism[] baptisms;

    public auto name()
    {
        return this._name;
    }

    public auto getId()
    {
        return this.id;
    }
}

@Table("priests")
public class Priest
{
    size_t id;
    public string _name;
    public string _address;

    size_t _dateAdded, _dateUpdated;


    this()
    {

    }

    this(string name, string address)
    {
        this._name = name;
        this._address = address;
        this._dateAdded = currTime();
    }

    public string name()
    {
        return this._name;
    }

    public string address()
    {
        return this._address;
    }

    public auto getId()
    {
        return this.id;
    }

    public string dateAdded()
    {
        import std.datetime.systime;
        SysTime d = SysTime.fromUnixTime(this._dateAdded);
        return d.toSimpleString();
    }

    public string dateUpdated()
    {
        import std.datetime.systime;
        SysTime d = SysTime.fromUnixTime(this._dateUpdated);
        return d.toSimpleString();
    }
}

import hibernated.core : ManyToMany, Id, Table, OneToMany, Entity;

@Table("baptisms")
public class Baptism
{
    size_t id;
    Church2 _church;
    // many baptisms can have many sponsors
    @ManyToMany
    ParentalFigure2[] _sponsors;

    size_t _dateAdded, _dateUpdated, _baptismalDate;
    Priest _priest;
    string _name;

    // TODO: Somehow this must be unique to the church (I guess)
    size_t regNumber;

    alias title = name;

    public auto getId()
    {
        return this.id;
    }

    public auto church()
    {
        return this._church;
    }

    public auto name()
    {
        return this._name;
    }

    public string dateAdded()
    {
        import std.datetime.systime;
        SysTime d = SysTime.fromUnixTime(this._dateAdded);
        return d.toSimpleString();
    }

    public string dateUpdated()
    {
        import std.datetime.systime;
        SysTime d = SysTime.fromUnixTime(this._dateUpdated);
        return d.toSimpleString();
    }

    public string getBaptismalDate()
    {
        import std.datetime.systime;
        SysTime d = SysTime.fromUnixTime(this._baptismalDate);
        return d.toSimpleString();
    }
}

public struct BaptismReg
{
    private string _parish;

}

public final class BaptismalEntry
{
    private size_t _id;
    private string _t; // title (name of person being baptised)

	private ptrdiff_t _da;

    // fatherly and mother parental figures
    private size_t[] _parentalFigures;

    private string[] _spns;
    private string _place_ofBirth;
    private string _baptismalDate;
    private string _byPriest; // the priest who baptised you
    private string _baptismalChurch; // where you were baptised

    this
    (
        size_t id,
        string title,
        size_t[] parentalFigureIds,
        ptrdiff_t dateAdded
    )
    {
        this._id = id;
        this._t = title;
        this._parentalFigures = parentalFigureIds;
        this._da = dateAdded;
    }


    this
    (
        string title,
        size_t[] parentalFigureIds
    )
    {
        this(0, title, parentalFigureIds, 0);
    }

    this
    (
        size_t id,
        string title,
        ptrdiff_t dateAdded
    )
    {
        this(id, title, [], dateAdded);
    }
    

    public void addSponsor(string s)
    {
        this._spns ~= s;
    }

    public string[] sponsors()
    {
        return this._spns;
    }

    public string title()
    {
        return this._t;
    }

    public size_t id()
    {
        return this._id;
    }

    public size_t[] parentalFigureIds()
    {
        return this._parentalFigures;
    }

    public string name()
    {
    	return this._t;
    }

	public string dateAdded()
    {
        import std.datetime.systime;
        SysTime d = SysTime.fromUnixTime(this._da);
        return d.toSimpleString();
    }

    public void setBaptismalDate(string s)
    {
        this._baptismalDate = s;
    }

    public string getBaptismalDate()
    {
        return this._baptismalDate;
    }

    public override string toString()
    {
    	import std.string : format;
    	return format
    	(
    		"%s (id: %d, name: %s)",
    		"BaptismalEntry",
    		id(),
    		name()
    	);
    }
}
