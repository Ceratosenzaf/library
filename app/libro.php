<?php
include('../utils/check-route.php');
check_user(true);
check_area('app');

include('../utils/db.php');

$isbn = $_GET['isbn'] ?? null;
if (!$isbn) redirect('./');
$_SESSION['isbn'] = $isbn;

function get_book()
{
  $isbn = $_SESSION['isbn'];

  $sql = "
  SELECT l.isbn, l.titolo, l.trama, l.pagine, l.pubblicazione, ce.nome editore FROM libro l
  JOIN casa_editrice ce ON ce.id = l.editore
  WHERE l.isbn = $1
  LIMIT 1
  ";

  $query_name = "libro-$isbn";

  $db = open_pg_connection();
  $res = pg_prepare($db, $query_name, $sql);
  $res = pg_execute($db, $query_name, array($isbn));

  if (!$res) return;
  return pg_fetch_assoc($res);
}

function get_autori()
{
  $isbn = $_SESSION['isbn'];

  $sql = "
  SELECT a.nome, a.cognome, a.pseudonimo FROM scrittura s 
  JOIN autore a ON a.id = s.autore 
  WHERE s.libro = $1
  ";

  $query_name = "autori-$isbn";

  $db = open_pg_connection();
  $res = pg_prepare($db, $query_name, $sql);
  $res = pg_execute($db, $query_name, array($isbn));

  if (!$res) return;

  $data = array();

  while ($row = pg_fetch_assoc($res))
    array_push($data, $row);

  return $data;
}


function get_sedi_e_copie()
{
  $isbn = $_SESSION['isbn'];

  $sql = "
  SELECT s.id, s.indirizzo, c.nome, count(k.id) copie FROM sede s 
  JOIN citta c ON c.id = s.citta 
  JOIN copia k ON k.sede = s.id 
  WHERE 
    k.disponibile = TRUE AND
    k.archiviato = FALSE AND
    k.libro = $1
  GROUP BY s.id, c.nome
  ORDER BY c.nome, s.indirizzo
  ";

  $query_name = "copie-$isbn";

  $db = open_pg_connection();
  $res = pg_prepare($db, $query_name, $sql);
  $res = pg_execute($db, $query_name, array($isbn));

  if (!$res) return;

  $data = array();

  while ($row = pg_fetch_assoc($res))
    array_push($data, $row);

  return $data;
}
?>

<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Portale lettori - MyBiblioteca</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous" />
  <link rel="stylesheet" href="../index.css">
</head>

<body>
  <?php include('../components/navbar.php') ?>
  <?php
  $libro = get_book();
  $autori = get_autori();
  $sedi = get_sedi_e_copie();

  include('../components/card.php');

  print '<div>';
  print '<h1>' . $libro['titolo'] . '</h1>';
  print '<h5>di ';
  foreach ($autori as $i => $autore) {
    if (isset($autore['pseudonimo'])) print $autore['pseudonimo'];
    else if (isset($autore['nome']) && isset($autore['cognome'])) print $autore['nome'] . ' ' . $autore['cognome'];
    else print $autore['nome'] ?? $autore['cognome'] ?? 'ignoto';
    if ($i != count($autori) - 1) print ', ';
  }
  print '</h5>';
  print '</div>';

  print '<p class="text-justify">' . $libro['trama'] . '</p>';

  print '<div class="row row-cols-1 row-cols-sm-2 row-cols-md-3 justify-content-center g-4 mb-4">';
  print '<div class="col">' . get_card('Pubblicazione', $libro['pubblicazione']) . '</div>';
  print '<div class="col text-capitalize">' . get_card('Editore', $libro['editore']) . '</div>';
  print '<div class="col">' . get_card('Pagine', $libro['pagine']) . '</div>';
  print '</div>';

  $copieTotali = 0;
  foreach ($sedi as $sede)
    $copieTotali += $sede['copie'];

  if (!$copieTotali) print '<h3>Al momento non disponibile</h3>';
  else {
    print '<h3>Prendilo in prestito!</h3>';
    print '<form action="prenota.php" method="POST" class="mx-auto" style="width:fit-content;">';
    print '<input class="form-control text-center" name="isbn" title="isbn" placeholder="isbn" type="text" disabled readonly value="' . $_SESSION['isbn'] . '">';
    print '<select name="sede" title="sede" class="form-control text-center d-block my-2" style="max-width:max-content;">';
    print '<option value="null">Sede qualsiasi</option>';
    foreach ($sedi as $sede) {
      $copie = $sede['copie'];
      $disabled = $copie == 0 ? 'disabled' : '';
      print "<option $disabled value=\"" . $sede['id'] . '">' . $sede['nome'] . ' - ' . $sede['indirizzo'] . " ($copie copie disponibili)</option>";
    }
    print '</select>';
    print '<button class="btn btn-primary" type="submit">Prenota</button>';
    print '</form>';
  }

  ?>
</body>

</html>