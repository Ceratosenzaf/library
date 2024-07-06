<?php

function get_card($header, $titolo)
{
  return "
    <div class=\"card mb-3\">
      <div class=\"card-header\">$header</div>
      <div class=\"card-body\">
        <h5 class=\"card-title\">$titolo</h5>
      </div>
    </div>";
}
