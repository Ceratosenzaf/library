<?php
include('../utils/redirect.php');

session_start();

function check_user($expected)
{
  $isLogged = isset($_SESSION['user']);

  if ($isLogged == $expected) return true;

  unset($_SESSION['user']);
  redirect('../');
}

function check_area($area)
{
  $currentArea = $_SESSION['area'] ?? null;

  if ($currentArea == $area) return true;

  if ($currentArea) redirect('../' . $currentArea);

  unset($_SESSION['area']);
  redirect('../');
}
