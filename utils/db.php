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

function start_pg_transaction($db)
{
  return pg_query($db, "BEGIN");
}

function commit_pg_transaction($db)
{
  return pg_query($db, "COMMIT");
}

function rollback_pg_transaction($db)
{
  return pg_query($db, "ROLLBACK");
}

function value_or_null($v)
{
  return empty($v) ? null : $v;
}

function get_pg_parsed_error($db)
{
  $str = pg_last_error($db);
  $offset = 6;
  return substr($str, $offset, strpos($str, 'CONTEXT') - $offset);
}

function log_prestito($prestito, $tipo, $func)
{

  $db = open_pg_connection();
  start_pg_transaction($db);

  function rollback_and_return($db)
  {
    rollback_pg_transaction($db);
    return false;
  }

  $sql = "SELECT * FROM prestito WHERE id = $1";
  $query_name = "select-$prestito";
  pg_prepare($db, $query_name, $sql);

  // dati pre
  $res_pre = pg_execute($db, $query_name, array($prestito));
  if (!$res_pre) return rollback_and_return($db);
  $dati_pre = pg_fetch_assoc($res_pre);
  if (!$dati_pre) return rollback_and_return($db);

  // update / insert
  $func($db);

  // dati post
  $res_post = pg_execute($db, $query_name, array($prestito));
  if (!$res_post) return rollback_and_return($db);
  $dati_post = pg_fetch_assoc($res_post);
  if (!$dati_post) return rollback_and_return($db);

  // log
  $bibliotecario = $_SESSION['area'] == 'admin' ? ($_SESSION['user'] ?? null) : null;
  $sql = "
  INSERT INTO log (tipo, prestito, bibliotecario, dati_pre, dati_post)
  VALUES ($1, $2, $3, $4, $5)
  ";
  $res = pg_prepare($db, "log-$prestito", $sql);
  $res = pg_execute($db, "log-$prestito", array($tipo, $prestito, value_or_null($bibliotecario), json_encode($dati_pre), json_encode($dati_post)));

  if (!$res) return rollback_and_return($db);

  commit_pg_transaction($db);
  return true;
}
