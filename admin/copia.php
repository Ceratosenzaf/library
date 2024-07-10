<?php
include('../utils/check-route.php');
check_user(true);
check_area('admin');

include('../utils/db.php');

$id = $_GET['id'] ?? null;
$_SESSION['copia'] = $id;

function get_copy()
{
  $id = $_SESSION['copia'];
  if (!$id) return;

  $sql = "
  SELECT * FROM copia c
  WHERE c.id = $1
  LIMIT 1
  ";

  $query_name = "copy-$id";

  $db = open_pg_connection();
  $res = pg_prepare($db, $query_name, $sql);
  $res = pg_execute($db, $query_name, array($id));

  if (!$res) return;
  return pg_fetch_assoc($res);
}

function get_all_sites()
{
  $sql = "
  SELECT s.id, s.indirizzo, c.nome FROM sede s
  JOIN citta c ON c.id = s.citta
  ORDER BY c.nome, s.indirizzo
  ";

  $query_name = "sites";

  $db = open_pg_connection();
  $res = pg_prepare($db, $query_name, $sql);
  $res = pg_execute($db, $query_name, array());

  if (!$res) return [];

  $data = array();

  while ($row = pg_fetch_assoc($res))
    array_push($data, $row);

  return $data;
}

function get_all_books()
{
  $sql = "
  SELECT l.isbn, l.titolo FROM libro l
  ORDER BY l.titolo
  ";

  $query_name = "books";

  $db = open_pg_connection();
  $res = pg_prepare($db, $query_name, $sql);
  $res = pg_execute($db, $query_name, array());

  if (!$res) return [];

  $data = array();

  while ($row = pg_fetch_assoc($res))
    array_push($data, $row);

  return $data;
}
?>

<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Portale bibliotecari - MyBiblioteca</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous" />
  <link rel="stylesheet" href="../index.css" />
</head>

<body>
  <div>
    <?php include('../components/navbar.php') ?>

    <div class="center d-flex flex-column gap-4">
      <h1 style="margin-top: -56px;">
        <?php print $_SESSION['copia'] ? 'Modifica copia' : 'Crea una nuova copia'; ?>
      </h1>
      <form method="post" action="<?php print $_SESSION['copia'] ? 'edit-copy.php' : 'create-copy.php'; ?>" class="d-flex flex-column gap-2 mb-4">
        <?php
        include('../utils/nome.php');

        $copia = get_copy();
        $sites = get_all_sites();
        $books = get_all_books();
        function get_v($k)
        {
          global $copia;
          if (!$copia) return;
          return $copia[$k];
        }

        $disabled = $_SESSION['copia'] ? 'disabled': '';

        print '<select name="libro" title="libro" class="form-control text-center d-block" required '.($_SESSION['copia'] ? 'disabled': '').' >';
        print '<option value="" disabled '.($_SESSION['copia'] ? '' : 'selected').'>libro</option>';
        foreach ($books as $book) {
          $selected = get_v('libro') == $book['isbn'] ? 'selected': '';
          print "<option $selected value=\"" . $book['isbn'] . '">' . $book['titolo']. '</option>';
        }
        print '</select>';

        print '<select name="sede" title="sede" class="form-control text-center d-block" required >';
        print '<option value="" disabled '.($_SESSION['copia'] ? '' : 'selected').'>sede</option>';
        foreach ($sites as $site) {
          $selected = get_v('sede') == $site['id'] ? 'selected': '';
          print "<option $selected value=\"" . $site['id'] . '">' . get_site_name($site['nome'], $site['indirizzo']). '</option>';
        }
        print '</select>';

        print '
        <div class="form-check text-left max-w-content mx-auto">
          <input class="form-check-input" type="checkbox" value="true" name="disponibile" id="disponibile" disabled readonly ' . (get_v('disponibile') == 'f' ? '' : 'checked') . ' />
          <label class="form-check-label" for="disponibile">
            Disponibile
          </label>
        </div>
        ';

        print '
        <div class="form-check text-left max-w-content mx-auto">
          <input class="form-check-input" type="checkbox" value="true" name="archiviato" id="archiviato" '.($_SESSION['copia'] ? '': 'disabled').' ' . (get_v('archiviato') == 't' ? 'checked' : '') . ' />
          <label class="form-check-label" for="archiviato">
            Archiviato
          </label>
        </div>
        ';

        print '<button type="submit" class="btn btn-primary">' . ($_SESSION['copia'] ? 'Modifica' : 'Crea') . '</button>';
        ?>
      </form>

      <?php if ($_SESSION['copia']) print '<a href="./prestiti.php?copia=' . $_SESSION['copia'] . '">Prestiti</a>'; ?>
    </div>
  </div>
</body>

</html>