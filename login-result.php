<?php

include './utils/db.php';
include './utils/redirect.php';
include './utils/codice-fiscale.php';

use NigroSimone\CodiceFiscale;

session_start();

$cf = $_POST['cf'] ?? '';
$password = $_POST['password'] ?? '';

if ($cf == '' || $password == '')
  redirect_error('input');

$area = $_SESSION['area'];
$table = $area == 'admin' ? 'bibliotecario' : 'lettore';
$hashedPassword = md5($password);

$sql = "SELECT * FROM $table WHERE cf = $1";

$db = open_pg_connection();
$res = pg_prepare($db, 'user', $sql);
$res = pg_execute($db, 'user', array($cf));

if (!$res) redirect_error('credentials');
$row = pg_fetch_assoc($res);

if ($row) {
  if ($row['password'] != $hashedPassword) redirect_error('credentials');

  $_SESSION['user'] = $cf;
  redirect($area);
}

if ($area == 'admin')
  redirect_error('credentials');

$checkCF = new CodiceFiscale();
if (!$checkCF->validaCodiceFiscale($cf)) redirect_error('input');

$_SESSION['cf'] = $cf;
$_SESSION['password'] = $hashedPassword;
redirect('signup.php');
