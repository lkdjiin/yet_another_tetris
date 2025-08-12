# Notes

## Liens

- Tetris Guideline : https://tetris.wiki/Tetris_Guideline
- Codes couleur RGB : http://www.digital-images.net/temp/RGB_Grey_equivs.jpg

## Speed
| level | frames/step |
|-------|-------------|
| 1     | 50
| 2     | 45
| 3     | 40
| 4     | 35
| 5     | 31
| 6     | 27
| 7     | 23
| 8     | 20
| 9     | 18
| 10    | 16
| 11    | 15
| 12    | 14
| 13    | 13
| 14    | 12
| 15    | 11
| 16    | 10
| 17    |  9
| 18    |  8
| 19    |  7
| 20    |  6
| 21    |  5
| 22    |  4
| 23    |  3
| 24    |  2
| 25    |  1


## Algo pour tester si une place est libre en dessous

Trouver, pour chaque colonne, la valeur du rang le plus bas.
Une colonne peut ne pas exister.
La valeur du rang le plus bas est en fait le nombre le plus élevé.

Ex 1 :

    0° => [[0, 0], [0, 1], [0, 2], [-1, 0]],

    colonne 0 : 0,0
    colonne 1 : 0,1
    colonne 2 : 0,2

    {0=>[[0, 0], [-1, 0]], 1=>[[0, 1]], 2=>[[0, 2]]}

Ex 2 :

    90° => [[-1, 1], [0, 1], [1, 1], [1, 0]],

    colonne 0 : 1,0
    colonne 1 : 1,1
    colonne 2 : aucune

    {1=>[[-1, 1], [0, 1], [1, 1]], 0=>[[1, 0]]}

En additionnant ces coordonnées à celles de la pièce on _devrait_ trouver les
coordonnées du playfield qui doivent être vides.

## Algo pour trouver si une place est libre à gauche
Trouver, pour chaque rangée, la valeur de la colonne la plus à gauche.
Une rangée peut ne pas exister.
La valeur de la colonne la plus à gauche est en fait le nombre le plus petit.

## Algo pour trouver si une place est libre à droite
Trouver, pour chaque rangée, la valeur de la colonne la plus à droite.
Une rangée peut ne pas exister.
La valeur de la colonne la plus à droite est en fait le nombre le plus grand.
