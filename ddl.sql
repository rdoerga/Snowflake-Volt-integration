create stream volttopic export to target test (
  name varchar(100) not null,
  telephone varchar(30) not null,
  email varchar(100)
);

create procedure pub_personalia as insert into volttopic values ?,?,?;

