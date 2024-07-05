<?php

include './utils/db.php';
include './utils/redirect.php';

session_start();

$cf = $_SESSION['cf'] ?? '';
$password = $_SESSION['password'] ?? '';
$nome = $_POST['nome'] ?? '';
$cognome = $_POST['cognome'] ?? '';

unset($_SESSION['cf']);
unset($_SESSION['password']);

if ($cf == '' || $password == '' || $nome == '' || $cognome == '')
  redirect_error('input');

// TODO: valida nome e cognome col cf

$sql = "INSERT INTO lettore (cf, nome, cognome, password) VALUES ($1, $2, $3, $4)";

$db = open_pg_connection();
$res = pg_prepare($db, 'new-user', $sql);
$res = pg_execute($db, 'new-user', array($cf, $nome, $cognome, $password));

if (!$res) redirect_error('credentials');

$_SESSION['user'] = $cf;
redirect($_SESSION['area']);
