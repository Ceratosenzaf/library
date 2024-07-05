<?php

function redirect($path)
{
  header("Location:$path");
  exit();
}

function redirect_error($code)
{
  $_SESSION['error'] = $code;
  redirect('error.php');
}
