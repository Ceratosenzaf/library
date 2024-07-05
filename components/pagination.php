<?php
function get_link($page, $search)
{
  if ($search) return "./catalogo.php?page=$page&search=$search";
  return "./catalogo.php?page=$page";
}

function get_pagination($items, $pagination, $page, $search)
{
  if (!$items) return;

  $totPages = ceil($items / $pagination);
  $min = 1;
  $max = $totPages;

  $prev = max($page - 1, $min);
  $next = min($page + 1, $max);

  print('<nav><ul class="pagination justify-content-center">');

  $disabled = $prev == $min ? 'disabled' : null;
  print(
    "
    <li class=\"page-item $disabled\">
      <a class=\"page-link\" href=" . get_link($prev, $search) . ">
        <span>&laquo;</span>
      </a>
    </li>
  "
  );

  for ($i = 1; $i <= $totPages; $i++) {
    $active = $page == $i ? 'active' : null;
    print(
      "<li class=\"page-item $active\"><a class=\"page-link\" href=" . get_link($i, $search) . ">$i</a></li>"
    );
  }

  $disabled = $next == $max ? 'disabled' : null;
  print(
    "
      <li class=\"page-item $disabled\">
        <a class=\"page-link\" href=" . get_link($next, $search) . ">
          <span>&raquo;</span>
        </a>
      </li>
    "
  );

  print('</ul></nav>');
}
