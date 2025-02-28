<?php

include '../utils/db.php';
include '../utils/redirect.php';
include '../utils/codice-fiscale.php';

use NigroSimone\CodiceFiscale;

session_start();

$cf = $_POST['cf'] ?? '';
$nome = $_POST['nome'] ?? '';
$cognome = $_POST['cognome'] ?? '';
$password = $_POST['password'] ?? '';
$premium = isset($_POST['premium']) ? 'TRUE': 'FALSE';

if ($cf == '' || $password == '' || $nome == '' || $cognome == '')
  redirect_error('input');

$checkCF = new CodiceFiscale();
if (!$checkCF->validaCodiceFiscale($cf)) redirect_error('input');

// TODO: valida nome e cognome col cf

$sql = "INSERT INTO lettore (cf, nome, cognome, password, premium) VALUES (upper($1), $2, $3, $4, $5)";

$db = open_pg_connection();
$res = pg_prepare($db, 'new-user', $sql);
$res = pg_execute($db, 'new-user', array($cf, $nome, $cognome, md5($password), $premium));

if (!$res) redirect_error('input');

redirect('./lettori.php');
