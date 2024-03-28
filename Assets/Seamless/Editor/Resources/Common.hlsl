float mod(float x, float y) {
    if(y > 1e-3)
        return x - y * floor(x / y);
    return 0.0;
}
float2 mod(float2 x, float2 y) {
    if (y.x > 1e-3 && y.y > 1e-3)
        return x - y * floor(x / y);
    return float2(0.0, 0.0);
}
float3 mod(float3 x, float3 y) {
    if (y.x > 1e-3 && y.y > 1e-3 && y.z > 1e-3)
        return x - y * floor(x / y);
    return float3(0.0, 0.0, 0.0);
}

int2 WrapCoord(int2 aCoord, uint2 aSize)
{
    int2 lOutCoord = aCoord;

    lOutCoord.x = lOutCoord.x % aSize.x;
    lOutCoord.y = lOutCoord.y % aSize.y;

    lOutCoord.x = (lOutCoord.x < 0) ? aSize.x + lOutCoord.x : lOutCoord.x;
    lOutCoord.y = (lOutCoord.y < 0) ? aSize.y + lOutCoord.y : lOutCoord.y;

    return lOutCoord;
}
int WrapTo(int X, uint W)
{
    X = X % W;

    if (X < 0)
    {
        X += W;
    }

    return X;
}
int2 WrapTo(int2 X, uint2 W)
{
    X.x = WrapTo(X.x, W.x);
    X.y = WrapTo(X.y, W.y);
    return X;
}
