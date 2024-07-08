<?php

include('../utils/nome.php');

function get_simple_card($header, $titolo)
{
  return "
    <div class=\"card mb-3\">
      <div class=\"card-header\">$header</div>
      <div class=\"card-body\">
        <h5 class=\"card-title\">$titolo</h5>
      </div>
    </div>";
}

function get_card($titolo, $sottotitolo, $contenuto, $link, $linkLabel = 'dettagli', $titleClass = '', $subtitleClass = '', $textClass = '', $linkClass = '')
{
  return "
    <div class=\"card\">
      <div class=\"card-body\">
        <h5 class=\"card-title $titleClass\">$titolo</h5>
        <h6 class=\"card-subtitle mb-2 text-muted $subtitleClass\">$sottotitolo</h6>
        <p class=\"card-text $textClass\">$contenuto</p>
        <a href=\"$link\" class=\"card-link $linkClass\">$linkLabel</a>
      </div>
    </div>";
}

function get_book_card($titolo, $isbn, $trama)
{
  return get_card($titolo, $isbn, $trama, "libro.php?isbn=$isbn");
}

function get_user_card($cf, $nome, $cognome)
{
  return get_card(get_user_name($nome, $cognome), $cf, null, "lettore.php?cf=$cf", 'dettagli', 'text-capitalize', 'text-uppercase');
}

function get_site_card($id, $via, $citta)
{
  return get_card($via, $citta, null, "sede.php?id=$id", 'dettagli', 'text-capitalize', 'text-capitalize');
}

function get_city_card($id, $nome)
{
  return get_card($nome, null, null, "citta.php?id=$id", 'dettagli', 'text-capitalize');
}

function get_author_card($id, $nome, $cognome, $pseudonimo, $nascita, $morte, $biografia)
{
  $b = $nascita ?? 'sconosciuto';
  $d = $morte ?? 'vivo';
  return get_card(get_writer_name($pseudonimo, $nome, $cognome), "$b - $d", $biografia, "autore.php?id=$id", 'dettagli', 'text-capitalize');
}

function get_publisher_card($id, $nome, $fondazione, $cessazione)
{
  $b = $fondazione ?? 'sconosciuto';
  $d = $cessazione ?? 'attivo';
  return get_card($nome, "$b - $d", null, "editore.php?id=$id");
}

function get_copy_card($id, $titolo, $indirizzo, $citta)
{
  return get_card($titolo, get_site_name($citta, $indirizzo), null, "copia.php?id=$id");
}

function get_lend_card($id, $inizio, $scadenza, $riconsegna)
{
  $e = $riconsegna ?? 'ora';
  return get_card("$inizio - $e", get_land_label($scadenza, $riconsegna), null, "prestito.php?id=$id");
}