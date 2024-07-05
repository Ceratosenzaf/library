<?php

function get_card($titolo, $isbn, $trama)
{
  return "
    <div class=\"card\">
      <div class=\"card-body\">
        <h5 class=\"card-title\">$titolo</h5>
        <h6 class=\"card-subtitle mb-2 text-muted\">$isbn</h6>
        <p class=\"card-text\">$trama</p>
        <a href=\"libro.php?isbn=$isbn\" class=\"card-link\">dettagli</a>
      </div>
    </div>";
}
