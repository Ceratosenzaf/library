<?php

function open_pg_connection()
{
  $host = "localhost";
  $port = "5432";
  $dbname = "postgres";
  $user = "postgres";
  $password = 'password';

  $connection = "host=$host port=$port dbname=$dbname user=$user password=$password";
  return pg_connect($connection);
}

function close_pg_connection($db)
{
  return pg_close($db);
}

function value_or_null($v)
{
  return empty($v) ? null: $v;
}
