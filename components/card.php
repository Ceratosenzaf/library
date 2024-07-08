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
  return get_card($titolo, $isbn, $trama, "libro.php?isbn=$isbn", 'dettagli');
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
