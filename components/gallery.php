<?php

include('../components/book-card.php');

function get_gallery($data)
{
  print('<div class="row row-cols-1 row-cols-sm-2 row-cols-md-3 justify-content-center g-4 mb-4">');
  foreach ($data as $row) {
    print(
        '<div class="col">'.
          get_card($row['titolo'], $row['isbn'], $row['trama']).
        '</div>'
    );
  }
  print('</div>');
}