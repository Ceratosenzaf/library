<?php

include './utils/db.php';
include './utils/redirect.php';

session_start();

$cf = $_POST['cf'] ?? '';
$password = $_POST['password'] ?? '';

if ($cf == '' || $password == '')
  redirect_error('input', false);

$area = $_SESSION['area'];
$table = $area == 'admin' ? 'bibliotecario' : 'lettore';
$hashedPassword = md5($password);

$sql = "SELECT * FROM $table WHERE cf = $1";

$db = open_pg_connection();
$res = pg_prepare($db, 'user', $sql);
$res = pg_execute($db, 'user', array($cf));

if (!$res) redirect_error('credentials', false);
$row = pg_fetch_assoc($res);

if (!$row) redirect_error('credentials', false);

if ($row['password'] != $hashedPassword) redirect_error('credentials', false);

$_SESSION['user'] = $cf;
redirect($area);
