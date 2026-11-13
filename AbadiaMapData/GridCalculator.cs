namespace AbadiaMapData;

public static class GridCalculator
{
    public static int GetGridSize(int floor) => floor switch
    {
        0 => 16,
        1 or 2 => 32,
        _ => throw new ArgumentOutOfRangeException(nameof(floor))
    };

    // La cuadrícula de prueba usa como referencia el centro exportado
    // de cada habitación, no el offset visual (aún por validar).
    public static bool Contains(RoomInfo room, double x, double y)
    {
        double half = GetGridSize(room.Floor) / 2.0;
        return x >= room.X - half && x < room.X + half
            && y >= room.Y - half && y < room.Y + half;
    }
}
