Hi there,

So I am working on a [Baptismal registry](https://github.com/deavmi/ChurchRegistry) program, effectively
a registar of people and where there are quite a number of
relations betweem them.

Every baptised person has an arbitrary amount of sponsors (parental figures),
etc.

I spent sometime switching away from hardcoded SQL, as it slowing
down development, to the hibernated ORM. So far I must say I am
really enjoying it; it has made development 100x faster and its
really nice.

Currently I am having a problem when I run the query to fetch
baptsisms:

```d
public Baptism getBaptism(SessionFactory sf, size_t id)
{
    auto s = sf.openSession();
    scope(exit)
    {
        s.close();
    }

    auto q = s.createQuery("FROM Baptism WHERE id = :ID").setParameter("ID", id);
    Baptism[] bs = q.list!(Baptism)();
    return bs[0];
}
```

This query should select all baptisms where the id matches, so
effectievely searching for a baptism by id. The error, however,
that I seem to get (and only realised once I printed it out)
is a complaint that seems to relate to it missing some sort
of parameter for linking against the `parental_figures`:

```
ddbc.core.SQLException@../../../../.dub/packages/ddbc/0.5.9/ddbc/source/ddbc/drivers/sqliteddbc.d(513): Error #1 while
preparing statement SELECT _t1.id, _t1._name FROM parental_figures AS _t1 WHERE  : incomplete input
```

Perhaps I have forgotten an attribute on some of my ORM
datatypes? I have them [here](https://github.com/deavmi/ChurchRegistry/blob/main/source/types.d#L202) as it seems that the
`WHERE ...` is empty and missing something. I am
very much under the impression that I am missing 
something with my annotations.

This is my first time using an ORM really, and Ihave
given the docs a look and marked the fields I think 
I needed to mark but I still seem to be getting that
error.

Any help would be appreciated very much! I can even
send a tip! :)
