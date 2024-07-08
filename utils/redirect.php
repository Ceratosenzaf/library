<?php

function redirect($path)
{
  header("Location:$path");
  exit();
}

function redirect_error($code, $nested = true)
{
  $_SESSION['error'] = $code;
  redirect($nested ? '../error.php' : 'error.php');
}
