<?php

function get_writer_name($pseudonimo, $nome, $cognome)
{
  if (isset($pseudonimo)) return $pseudonimo;
  if (isset($nome) && isset($cognome)) return "$nome $cognome";
  return $nome ?? $cognome ?? 'ignoto';
}

function get_user_name($nome, $cognome)
{
  if (isset($nome) && isset($cognome)) return "$nome $cognome";
  return $nome ?? $cognome ?? 'ignoto';
}


function get_site_name($citta, $indirizzo)
{
  return "$citta - $indirizzo";
}
