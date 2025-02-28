<?php
include './utils/db.php';
include './utils/redirect.php';

session_start();

$cf = $_SESSION['user'] ?? null;
if(!$cf) redirect_error('credentials', false);

$currentPassword = $_POST['currentPassword'];
$newPassword = $_POST['newPassword'];
if (!$currentPassword || !$newPassword) redirect_error('input', false);
if ($newPassword != $_POST['confirmNewPassword']) redirect_error('confirmPassword', false);

$area = $_SESSION['area'];
$table = $area == 'admin' ? 'bibliotecario' : 'lettore';

$sql = "SELECT * FROM $table WHERE cf = $1";

$db = open_pg_connection();
$res = pg_prepare($db, 'user', $sql);
$res = pg_execute($db, 'user', array($cf));

if (!$res) redirect_error('credentials', false);
$row = pg_fetch_assoc($res);

if(!$row) redirect_error('credentials', false);

$hashedPassword = md5($currentPassword);
if ($row['password'] != $hashedPassword) redirect_error('credentials', false);

$sql = "UPDATE $table SET password = $1 WHERE cf = $2";

$res = pg_prepare($db, 'update-password', $sql);
$res = pg_execute($db, 'update-password', array(md5($newPassword), $cf));

if (!$res) redirect_error('credentials', false);

redirect($area);