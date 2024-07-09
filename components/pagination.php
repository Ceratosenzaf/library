<?php
function get_link($page)
{
  $url = $_SERVER['REQUEST_URI'];
  $parsed_url = parse_url($url);


  parse_str($parsed_url['query'] ?? '', $query_params);
  $query_params['page'] = $page;

  $new_query_string = http_build_query($query_params);
  $new_url = $parsed_url['path'] . '?' . $new_query_string;
  
  return $new_url;
}

function get_pagination($items, $pagination, $page)
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
      <a class=\"page-link\" href=" . get_link($prev) . ">
        <span>&laquo;</span>
      </a>
    </li>
  "
  );

  for ($i = 1; $i <= $totPages; $i++) {
    $active = $page == $i ? 'active' : null;
    print(
      "<li class=\"page-item $active\"><a class=\"page-link\" href=" . get_link($i) . ">$i</a></li>"
    );
  }

  $disabled = $next == $max ? 'disabled' : null;
  print(
    "
      <li class=\"page-item $disabled\">
        <a class=\"page-link\" href=" . get_link($next) . ">
          <span>&raquo;</span>
        </a>
      </li>
    "
  );

  print('</ul></nav>');
}
