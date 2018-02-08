// Set numeric types' precision
precision mediump float;
precision mediump int;

// Basic values
const float PI = 3.14159265358;

const int WEBGL_SMOOTHING_STYLE_LINEAR = 0;
const int WEBGL_SMOOTHING_STYLE_FULL = 1;

const int LEVELS = %LEVELS%;
const float FIDELITY = %FIDELITY%;

// Uniforms
uniform bool forceTriangles;
uniform float trianglesOpacity;

uniform float maxTriangleHeight;
uniform float maxTriangleHalfBase;
uniform float maxTriangleBase;

// PARSER CONDITION / mode.gridPanX
    uniform float gridPanXCycleRatio;
// PARSER CONDITION END

// PARSER CONDITION / mode.gridPanY
    uniform float gridPanYCycleRatio;
// PARSER CONDITION END

// PARSER CONDITION / mode.gridRotationSource != 'none'
    uniform float gridRotation;
    uniform vec2 gridRotationCenter;
// PARSER CONDITION END

uniform float contrastThreshold;
uniform bool contrastIsTarget;

uniform float mouseCircleRadius;

uniform float mouseCircleWaveHeightRatio;
uniform float mouseCircleWaveCycles;
uniform float mouseCircleSmallWaveHeightRatio;
uniform float mouseCircleSmallWaveCycles;
uniform float mouseCircleWaveCycleRatio;


uniform float time;

uniform float horizontalCrop;
uniform float verticalCrop;

uniform float horizontalAlign;
uniform float verticalAlign;

uniform vec2 pointerPosition;
uniform float viewportAspectRatio;

uniform vec2 canvasResolution;
uniform float pixelRatio;

// PARSER CONDITION / mode.isMonkey
    uniform float monkeyTop;
// PARSER CONDITION END

// PARSER CONDITION / mode.isFlatGuitars
    uniform float flatGuitarsBgStartLeft;
    uniform float guitarTop;
    uniform float guitarWidth;
    uniform float guitarHeight;
// PARSER CONDITION END

uniform sampler2D texture;

// PARSER CONDITION / mode.bitmapArea
    uniform sampler2D bitmapAreaTexture;
// PARSER CONDITION END

// PARSER CONDITION / mode.isJWT
    uniform sampler2D jwtTexture;
// PARSER CONDITION END

// PARSER CONDITION / mode.isMonkey
    uniform sampler2D monkeyTexture;
// PARSER CONDITION END

// PARSER CONDITION / mode.isFlatGuitars
    uniform sampler2D flatGuitarsBgPattern;
// PARSER CONDITION END

// Varyings
varying vec2 canvasPosition;

// Own variables


vec2 getTextureCoordinates(vec2 point, float horizontalCrop, float verticalCrop)
{
    float x = point.x;
    float y = point.y;

    if (x < -1.0) x = -1.0;
    else if (x > 1.0) x = 1.0;

    if (y < -1.0) y = -1.0;
    else if (y > 1.0) y = 1.0;

    float textureX = point.x * horizontalCrop / 2.0 + .5 + (1.0 - horizontalCrop) / 2.0 * horizontalAlign;
    float textureY = -point.y * verticalCrop / 2.0 + .5 + (1.0 - verticalCrop) / 2.0 * verticalAlign;

    return vec2(textureX, textureY);
}

// PARSER CONDITION / !mode.isMonkey && !mode.isJWT && !mode.isFlatGuitars
    vec4 getColorInPoint(vec2 point, sampler2D texture, float horizontalCrop, float verticalCrop)
    {
        return texture2D(texture, getTextureCoordinates(point, horizontalCrop, verticalCrop));
    }
// PARSER CONDITION END

// PARSER CONDITION / mode.isMonkey || mode.isJWT || mode.isFlatGuitars

    float modulus(float base, float divider)
    {
        float division = base / divider;
        float value = (division - floor(division)) * divider;
        return value;
    }

    vec4 getObjectColor
    (
        vec2 canvasPoint,
        vec2 canvasAnchor,
        vec2 originCoords,
        vec2 originDimensions,
        vec2 offsetInPixels,
        bool flipX,
        vec2 targetDimensions,
        bool scaleForTarget,
        vec2 spriteDimensions,
        sampler2D texture
    )
    {
        vec2 objectOrigin = vec2(canvasAnchor);
        objectOrigin.x += offsetInPixels.x * pixelRatio / (canvasResolution.x / 2.0);
        objectOrigin.y += offsetInPixels.y * pixelRatio / (canvasResolution.y / 2.0);

        vec2 objectEnd = objectOrigin + targetDimensions * pixelRatio / (canvasResolution / 2.0);

        if
        (
            canvasPoint.x > objectOrigin.x
            &&
            canvasPoint.x < objectEnd.x
            &&
            canvasPoint.y > objectOrigin.y
            &&
            canvasPoint.y < objectEnd.y
        )
        {
            vec2 pointInOrigin;

            if (!scaleForTarget)
            {
                pointInOrigin = vec2
                (
                    (canvasPoint.x - objectOrigin.x) / (originDimensions.x * pixelRatio / (canvasResolution.x / 2.0)),
                    (canvasPoint.y - objectOrigin.y) / (originDimensions.y * pixelRatio / (canvasResolution.y / 2.0))
                );

                pointInOrigin.x = modulus(pointInOrigin.x, 1.0);
                pointInOrigin.y = modulus(pointInOrigin.y, 1.0);
            }
            else
            {
                pointInOrigin = vec2
                (
                    (canvasPoint.x - objectOrigin.x) / (objectEnd.x - objectOrigin.x),
                    (canvasPoint.y - objectOrigin.y) / (objectEnd.y - objectOrigin.y)
                );
            }

            if (flipX) pointInOrigin.x = 1.0 - pointInOrigin.x;

            vec2 pointInTexture = vec2
            (
                originCoords.x / spriteDimensions.x + pointInOrigin.x * originDimensions.x / spriteDimensions.x,
                originCoords.y / spriteDimensions.y + (1.0 - pointInOrigin.y) * originDimensions.y / spriteDimensions.y
            );

            return texture2D(texture, pointInTexture);
        }
        else
        {
            return vec4(0, 0, 0, 0);
        }
    }

    vec4 mergeColors(vec4 background, vec4 foreground)
    {
        vec4 resultingColor;
        if (background.r == 0.0 && background.g == 0.0 && background.b == 0.0 && background.a == 0.0)
        {
            return foreground;
        }
        else
        {
            float newAlpha = background.a + foreground.a;
            if (newAlpha > 1.0) newAlpha = 1.0;
            return (vec4
            (
                background.r * (1.0 - foreground.a) + foreground.r * (foreground.a),
                background.g * (1.0 - foreground.a) + foreground.g * (foreground.a),
                background.b * (1.0 - foreground.a) + foreground.b * (foreground.a),
                newAlpha
            ));
        }
        return foreground;
    }

    // PARSER CONDITION / mode.isMonkey
        vec2 SPRITE_DIMENSIONS = vec2(321.0, 334.0);
    // PARSER CONDITION END
    // PARSER CONDITION / mode.isJWT
        vec2 SPRITE_DIMENSIONS = vec2(127.0, 188.0);
    // PARSER CONDITION END


    vec4 getColorInPoint(vec2 point, sampler2D texture, float horizontalCrop, float verticalCrop)
    {
        vec4 resultingColor = vec4(.0, .0, .0, .000001); // Stupid values because of stupid Safari

        vec4 objectColor;
        
        // PARSER CONDITION / mode.isMonkey
            resultingColor = texture2D(texture, getTextureCoordinates(point, horizontalCrop, verticalCrop));

            // Arms
            objectColor = getObjectColor
            (
                point,                          // canvas point
                vec2(-1.0, monkeyTop),                // anchor
                vec2(194.0, 128.0),             // origin coords
                vec2(10.0, 11.0),               // origin dimensions
                vec2(50.0 + 77.0, -198.0),      // offset
                false,                          // flipX
                vec2(canvasResolution.x / pixelRatio - (77.0 + 50.0) * 2.0, 11.0),  // target dimensions
                false,
                SPRITE_DIMENSIONS,
                monkeyTexture
            );
            resultingColor = mergeColors(resultingColor, objectColor);
            
            // Left hand
            objectColor = getObjectColor
            (
                point,                          // canvas point
                vec2(-1.0, monkeyTop),                // anchor
                vec2(194.0, 140.0),             // origin coords
                vec2(78.0, 55.0),               // origin dimensions
                vec2(50.0, -55.0 - 143.0),      // offset
                false,                          // flipX
                vec2(78.0, 55.0),               // target dimensions
                false,
                SPRITE_DIMENSIONS,
                monkeyTexture
            );
            resultingColor = mergeColors(resultingColor, objectColor);
            
            // Right hand
            objectColor = getObjectColor
            (
                point,                          // canvas point
                vec2(1.0, monkeyTop),                 // anchor
                vec2(194.0, 140.0),             // origin coords
                vec2(78.0, 55.0),               // origin dimensions
                vec2(-50.0 - 78.0, -55.0 - 143.0),        // offset
                true,                           // flipX
                vec2(78.0, 55.0),               // target dimensions
                false,
                SPRITE_DIMENSIONS,
                monkeyTexture
            );
            resultingColor = mergeColors(resultingColor, objectColor);
            
            // Body
            objectColor = getObjectColor
            (
                point,                          // canvas point
                vec2(0, monkeyTop),                   // anchor
                vec2(1.0, 128.0),               // origin coords
                vec2(191.0, 205.0),             // origin dimensions
                vec2(-115.0, -265.0 - 96.0),    // offset
                false,                          // flipX
                vec2(191.0, 205.0),             // target dimensions
                false,
                SPRITE_DIMENSIONS,
                monkeyTexture
            );
            resultingColor = mergeColors(resultingColor, objectColor);
            
            // Head
            vec2 headOriginCoords = modulus(time, 2000.0) < 1000.0 ? vec2(1.0, 1.0) : vec2(161.0, 1.0);
            objectColor = getObjectColor
            (
                point,                          // canvas point
                vec2(0, monkeyTop),                   // anchor
                headOriginCoords,               // origin coords
                vec2(159.0, 126.0),             // origin dimensions
                vec2(-90.0, -181.0),            // offset
                false,                          // flipX
                vec2(159.0, 126.0),             // target dimensions
                false,
                SPRITE_DIMENSIONS,
                monkeyTexture
            );
            resultingColor = mergeColors(resultingColor, objectColor);
        // PARSER CONDITION END

        // PARSER CONDITION / mode.isJWT
            resultingColor = texture2D(texture, getTextureCoordinates(point, horizontalCrop, verticalCrop));

            // Ship Right
            float frame = floor((modulus(time, 4.0 * 30.0)) / 30.0);
            float originTop = 1.0 + 47.0 * frame;
            float offsetY = 5.0 * sin(time / 1800.0 * 3.1416);
            objectColor = getObjectColor
            (
                point,                          // canvas point
                vec2(0.0, 0.0),                 // anchor
                vec2(1.0, originTop),           // origin coords
                vec2(127.0, 45.0),              // origin dimensions
                vec2(0.0, -60.0 + offsetY),     // offset
                false,                          // flipX
                vec2(127.0, 45.0),              // target dimensions
                false,
                SPRITE_DIMENSIONS,
                jwtTexture
            );
            resultingColor = mergeColors(resultingColor, objectColor);

            // Ship Left
            frame = floor((modulus(time + 60.0, 4.0 * 30.0)) / 30.0);
            originTop = 1.0 + 47.0 * frame;
            offsetY = 3.0 * sin(time / 1500.0 * 3.1416);
            objectColor = getObjectColor
            (
                point,                              // canvas point
                vec2(0.0, 0.0),                     // anchor
                vec2(1.0, originTop),               // origin coords
                vec2(127.0, 45.0),                  // origin dimensions
                vec2(-100.0, -90.0 + offsetY),      // offset
                false,                              // flipX
                vec2(127.0 * .725, 45.0 * .725),    // target dimensions
                true,
                SPRITE_DIMENSIONS,
                jwtTexture
            );
            resultingColor = mergeColors(resultingColor, objectColor);
        // PARSER CONDITION END

        // PARSER CONDITION / mode.isFlatGuitars
            
            // BG Pattern
            resultingColor = vec4(23.0 / 255.0, 23.0 / 255.0, 23.0 / 255.0, 1);
            objectColor = getObjectColor
            (
                point,                          // canvas point
                vec2(flatGuitarsBgStartLeft, -1.0),                   // anchor
                vec2(0.0, 0.0),                 // origin coords
                vec2(24.0, 24.0),               // origin dimensions
                vec2(0.0, 0.0),                 // offset
                false,                          // flipX
                vec2(canvasResolution.x / pixelRatio * (1.0 - flatGuitarsBgStartLeft / 2.0), canvasResolution.y / pixelRatio),             // target dimensions
                false,
                vec2(24.0, 24.0),
                flatGuitarsBgPattern
            );
            resultingColor = mergeColors(resultingColor, objectColor);

            // Guitar
            objectColor = getObjectColor
            (
                point,                          // canvas point
                vec2(-1.0, guitarTop - guitarHeight),                   // anchor
                vec2(0.0, 0.0),                 // origin coords
                vec2(606.0, 856.0),             // origin dimensions
                vec2(0.0, 0.0),                 // offset
                false,                          // flipX
                vec2(canvasResolution.x / pixelRatio * (guitarWidth / 2.0), canvasResolution.y / pixelRatio * (guitarHeight / 2.0)),             // target dimensions
                true,
                vec2(606.0, 856.0),
                texture
            );
            resultingColor = mergeColors(resultingColor, objectColor);

            // // Ship Right
            // float frame = floor((modulus(time, 4.0 * 30.0)) / 30.0);
            // float originTop = 1.0 + 47.0 * frame;
            // float offsetY = 5.0 * sin(time / 1800.0 * 3.1416);
            // objectColor = getObjectColor
            // (
            //     point,                          // canvas point
            //     vec2(0.0, 0.0),                 // anchor
            //     vec2(1.0, originTop),           // origin coords
            //     vec2(127.0, 45.0),              // origin dimensions
            //     vec2(0.0, -60.0 + offsetY),     // offset
            //     false,                          // flipX
            //     vec2(127.0, 45.0),              // target dimensions
            //     false,
            //     SPRITE_DIMENSIONS,
            //     jwtTexture
            // );
            // resultingColor = mergeColors(resultingColor, objectColor);

            // // Ship Left
            // frame = floor((modulus(time + 60.0, 4.0 * 30.0)) / 30.0);
            // originTop = 1.0 + 47.0 * frame;
            // offsetY = 3.0 * sin(time / 1500.0 * 3.1416);
            // objectColor = getObjectColor
            // (
            //     point,                              // canvas point
            //     vec2(0.0, 0.0),                     // anchor
            //     vec2(1.0, originTop),               // origin coords
            //     vec2(127.0, 45.0),                  // origin dimensions
            //     vec2(-100.0, -90.0 + offsetY),      // offset
            //     false,                              // flipX
            //     vec2(127.0 * .725, 45.0 * .725),    // target dimensions
            //     true,
            //     SPRITE_DIMENSIONS,
            //     jwtTexture
            // );
            // resultingColor = mergeColors(resultingColor, objectColor);
        // PARSER CONDITION END

        return resultingColor;
    }
// PARSER CONDITION END

float rand(vec2 co)
{
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec2 rotate(vec2 targetPoint, vec2 center, float angle)
{
    float xDiff = targetPoint.x - center.x;
    float yDiff = targetPoint.y - center.y;

    float hypotenuse = pow(pow(xDiff, 2.0) + pow(yDiff, 2.0), .5);

    float originalAngle = atan(yDiff, xDiff);
    float resultingAngle = originalAngle + angle;

    float resultingXDiff = cos(resultingAngle) * hypotenuse;
    float resultingYDiff = sin(resultingAngle) * hypotenuse;

    return vec2(center.x + resultingXDiff, center.y + resultingYDiff);
}

vec2 applyAspectRatio(vec2 point, float aspectRatio)
{
    return vec2(point.x * aspectRatio, point.y);
}

float gridData_scaledBase;
float gridData_scaledHeight;

bool gridData_upperTriangle;

vec2 gridData_pointInGrid;

vec2 gridData_point;

void getGridDataForPoint(vec2 evaluatedPoint, float level)
{
    vec2 translatedPoint = vec2(evaluatedPoint);

    // if (parallaxX)
    // translatedPoint.x += parallaxXStrength * pointerPosition.x * pow(parallaxXDecay, level);

    // if (parallaxY)
    // translatedPoint.y += parallaxYStrength * pointerPosition.y * pow(parallaxYDecay, level);

    // PARSER CONDITION / mode.gridPanY
        translatedPoint.y += gridPanYCycleRatio * maxTriangleHeight * 2.0;
    // PARSER CONDITION END

    vec2 skewedPoint = vec2(translatedPoint.x + translatedPoint.y / maxTriangleHeight * (maxTriangleHalfBase / viewportAspectRatio), translatedPoint.y);

    // PARSER CONDITION / mode.gridPanX
        skewedPoint.x += gridPanXCycleRatio * maxTriangleBase;
    // PARSER CONDITION END

    float levelFactor = pow(2.0, level);

    float scaledBase = (maxTriangleBase / viewportAspectRatio / levelFactor);
    gridData_scaledBase = scaledBase;

    float scaledHeight = (maxTriangleHeight / levelFactor);
    gridData_scaledHeight = scaledHeight;

    float gridX = skewedPoint.x / scaledBase;

    float gridY = skewedPoint.y / scaledHeight;

    float column = floor(gridX);
    float row = floor(gridY);

    float innerX = gridX - column;
    float innerY = gridY - row;

    bool upperTriangle = innerX < innerY;
    gridData_upperTriangle = upperTriangle;

    float centeredX = column + (upperTriangle ? .25 : .75);

    float centeredY = row + (upperTriangle ? .75 : .25);

    vec2 pointInGrid = vec2(centeredX, centeredY);
    gridData_pointInGrid = pointInGrid;

    float pointX = pointInGrid.x * scaledBase;
    float pointY = pointInGrid.y * scaledHeight;
    pointX -= pointY / maxTriangleHeight * (maxTriangleHalfBase / viewportAspectRatio);

    // PARSER CONDITION / mode.gridPanX
        pointX -= gridPanXCycleRatio * maxTriangleBase;
    // PARSER CONDITION END

    // PARSER CONDITION / mode.gridPanY
        pointY -= gridPanYCycleRatio * maxTriangleHeight * 2.0;
    // PARSER CONDITION END

    vec2 point = vec2(pointX, pointY);
    gridData_point = point;
}

// PARSER CONDITION / mode.gridRotationSource != 'none'
    vec2 rotatePoint(vec2 sourcePoint, float rotation)
    {
        vec2 resultPoint = vec2(sourcePoint);

        if (rotation != 0.0)
        {
            resultPoint = applyAspectRatio(resultPoint, viewportAspectRatio);
            resultPoint = rotate(resultPoint, gridRotationCenter, rotation);
            resultPoint = applyAspectRatio(resultPoint, 1.0 / viewportAspectRatio);
        }

        return resultPoint;
    }
// PARSER CONDITION END

vec4 processAreaPixel(vec2 processingPoint)
{
    vec2 evaluatedPoint = vec2(processingPoint.x, processingPoint.y);

    // PARSER CONDITION / mode.gridRotationSource != 'none'
        evaluatedPoint = rotatePoint(evaluatedPoint, gridRotation);
    // PARSER CONDITION END

    vec4 pointColor;
    bool found = false;

    vec4 foundColors[LEVELS];
    bool foundTriangles[LEVELS];
    for (int level = 0; level < LEVELS; level++)
    {
        foundTriangles[level] = false;
    }

    for (int levelInt = 0; levelInt < LEVELS; levelInt++)
    {
        float level = float(levelInt);

        getGridDataForPoint(evaluatedPoint, level);

        float scaledBase = gridData_scaledBase;
        float scaledHeight = gridData_scaledHeight;

        bool upperTriangle = gridData_upperTriangle;

        vec2 pointInGrid = gridData_pointInGrid;

        vec2 point = gridData_point;

        // PARSER CONDITION / mode.gridRotationSource != 'none'
            point = rotatePoint(point, -gridRotation);
        // PARSER CONDITION END

        // PARSER CONDITION / mode.activeArea == Triangles.UNIFORM_ACTIVE_AREA

            vec2 neighbour1 = vec2(pointInGrid.x, pointInGrid.y);
            if (upperTriangle)
            {
                neighbour1.x += .5;
                neighbour1.y -= .5;
            }
            else
            {
                neighbour1.x -= .5;
                neighbour1.y += .5;   
            }

            vec2 neighbour2 = vec2(pointInGrid.x, pointInGrid.y);
            if (upperTriangle)
            {
                neighbour2.x -= .5;
                neighbour2.y -= .5;
            }
            else
            {
                neighbour2.x += .5;
                neighbour2.y += .5;   
            }

            vec2 neighbour3 = vec2(pointInGrid.x, pointInGrid.y);
            if (upperTriangle)
            {
                neighbour3.x += .5;
                neighbour3.y += .5;
            }
            else
            {
                neighbour3.x -= .5;
                neighbour3.y -= .5;   
            }

            neighbour1.x *= scaledBase;
            neighbour1.y *= scaledHeight;
            neighbour1.x -= neighbour1.y / maxTriangleHeight * (maxTriangleHalfBase / viewportAspectRatio);

            neighbour2.x *= scaledBase;
            neighbour2.y *= scaledHeight;
            neighbour2.x -= neighbour2.y / maxTriangleHeight * (maxTriangleHalfBase / viewportAspectRatio);

            neighbour3.x *= scaledBase;
            neighbour3.y *= scaledHeight;
            neighbour3.x -= neighbour3.y / maxTriangleHeight * (maxTriangleHalfBase / viewportAspectRatio);

            pointColor = getColorInPoint(point, texture, horizontalCrop, verticalCrop);

            float difference = 0.0;
            
            vec4 neighbour1Color = getColorInPoint(neighbour1, texture, horizontalCrop, verticalCrop);
            difference += abs(neighbour1Color.r - pointColor.r) / 9.0;
            difference += abs(neighbour1Color.g - pointColor.g) / 9.0;
            difference += abs(neighbour1Color.b - pointColor.b) / 9.0;
            
            vec4 neighbour2Color = getColorInPoint(neighbour2, texture, horizontalCrop, verticalCrop);
            difference += abs(neighbour2Color.r - pointColor.r) / 9.0;
            difference += abs(neighbour2Color.g - pointColor.g) / 9.0;
            difference += abs(neighbour2Color.b - pointColor.b) / 9.0;
            
            vec4 neighbour3Color = getColorInPoint(neighbour3, texture, horizontalCrop, verticalCrop);
            difference += abs(neighbour3Color.r - pointColor.r) / 9.0;
            difference += abs(neighbour3Color.g - pointColor.g) / 9.0;
            difference += abs(neighbour3Color.b - pointColor.b) / 9.0;

            if
            (
                (
                    contrastIsTarget
                    &&
                    difference > contrastThreshold
                )
                ||
                (
                    !contrastIsTarget
                    &&
                    difference < contrastThreshold
                )
            )
            {
                // if (!parallaxPreserveColor)
                // {
                //     if (parallaxX)
                //     point.x -= parallaxXStrength * pointerPosition.x * pow(parallaxXDecay, level);

                //     if (parallaxY)
                //     point.y -= parallaxYStrength * pointerPosition.y * pow(parallaxYDecay, level);
                // }

                pointColor = getColorInPoint(point, texture, horizontalCrop, verticalCrop);

                found = true;

                // PARSER CONDITION / !mode.overlapTriangles
                    break;
                // PARSER CONDITION END
                // PARSER CONDITION / mode.overlapTriangles
                    foundTriangles[int(level)] = true;
                    foundColors[int(level)] = pointColor;
                // PARSER CONDITION END
            }

        // PARSER CONDITION END
        // PARSER CONDITION / mode.activeArea == Triangles.MOUSE_ACTIVE_AREA

            float distanceX = (point.x - pointerPosition.x) * viewportAspectRatio;
            float distanceY = point.y - pointerPosition.y;

            float distance = pow(pow(distanceX, 2.0) + pow(distanceY, 2.0), .5);

            float distanceRatio = distance / mouseCircleRadius;

            // PARSER CONDITION / mode.mouseAreaShape == Triangles.WAVY_CIRCLE_MOUSE_AREA
            
                float angle = atan(distanceY, distanceX);

                float distanceRatioModifier = 1.0;
                distanceRatioModifier *= 1.0 + cos((angle + PI * 2.0 / mouseCircleWaveCycles * mouseCircleWaveCycleRatio * (1.0 + level * .1)) * mouseCircleWaveCycles) * mouseCircleWaveHeightRatio / (level + 1.0);
                distanceRatioModifier *= 1.0 + cos((angle - PI * 2.0 / mouseCircleSmallWaveCycles * mouseCircleWaveCycleRatio * (1.0 + level * .1)) * mouseCircleSmallWaveCycles) * mouseCircleSmallWaveHeightRatio / (level + 1.0);

                distanceRatio *= distanceRatioModifier;

            // PARSER CONDITION END


            // PARSER CONDITION / mode.invertArea
                distanceRatio = 1.0 - distanceRatio;
            // PARSER CONDITION END

            bool foundOnBitmapArea = false;

            // PARSER CONDITION / mode.bitmapArea
                float bitmapAreaRatio = getColorInPoint(point, bitmapAreaTexture, horizontalCrop, verticalCrop).r;
                
                float maxLevel = floor(float(LEVELS) * (1.0 - bitmapAreaRatio) + .5);

                if (level >= maxLevel) foundOnBitmapArea = true;
            // PARSER CONDITION END

            if (foundOnBitmapArea || distanceRatio < 1.0)
            {
                float distanceLevel = 1.0 + floor(distanceRatio * float(LEVELS));

                if (foundOnBitmapArea || (level + 1.0) >= distanceLevel)
                {
                    pointColor = getColorInPoint(point, texture, horizontalCrop, verticalCrop);

                    found = true;

                    // PARSER CONDITION / !mode.overlapTriangles
                        break;
                    // PARSER CONDITION END
                    // PARSER CONDITION / mode.overlapTriangles
                        foundTriangles[int(level)] = true;
                        foundColors[int(level)] = pointColor;
                    // PARSER CONDITION END
                }
            }

        // PARSER CONDITION END
    }

    vec4 resultingColor;

    // PARSER CONDITION / !mode.forceTriangles
        if (found)
        {
    // PARSER CONDITION END
            if (trianglesOpacity == 1.0)
            resultingColor = pointColor;
            else
            {
                vec4 imageColor = getColorInPoint(processingPoint, texture, horizontalCrop, verticalCrop);

                if
                (
                    // PARSER CONDITION / !mode.overlapTriangles
                        true
                    // PARSER CONDITION END
                    // PARSER CONDITION / mode.overlapTriangles
                        false
                    // PARSER CONDITION END
                    ||
                    (
                        forceTriangles
                        &&
                        !found
                    )
                )
                {
                    resultingColor = imageColor * (1.0 - trianglesOpacity) + pointColor * trianglesOpacity;
                }
                else
                {
                    resultingColor = vec4(imageColor);
                    
                    for (int levelInt = 0; levelInt < LEVELS; levelInt++)
                    {
                        float level = float(levelInt);

                        if (foundTriangles[LEVELS - 1 - levelInt])
                        {
                            vec4 triangleColor = foundColors[LEVELS - 1 - levelInt];
                            resultingColor = resultingColor * (1.0 - trianglesOpacity) + triangleColor * trianglesOpacity;
                        }
                    }
                }
            }
    // PARSER CONDITION / !mode.forceTriangles
        }
        else
        resultingColor = getColorInPoint(processingPoint, texture, horizontalCrop, verticalCrop);
    // PARSER CONDITION END


    return resultingColor;
}

vec4 processPixel(vec2 processingPoint)
{
    return processAreaPixel(processingPoint);
}

void main()
{
    // PARSER CONDITION / pixelRatio > 1 || self.smoothingTechnique != "webgl" || self.smoothingStrength == 1
        gl_FragColor = processPixel(canvasPosition);
    // PARSER CONDITION END
    // PARSER CONDITION / pixelRatio <= 1 && self.smoothingTechnique == "webgl" && self.smoothingStrength > 1
        // PARSER CONDITION / self.webglSmoothingStyle == Triangles.WEBGL_SMOOTHING_STYLE_LINEAR
            vec4 finalColor = vec4(0, 0, 0, 0);

            for (float i = .0; i < FIDELITY; i++)
            {
                vec2 point = vec2(canvasPosition);

                if (i > .0) point.x += i / (canvasResolution.x / 2.0) / FIDELITY;
                if (i > .0) point.y += i / (canvasResolution.y / 2.0) / FIDELITY;

                vec4 pointColor = processPixel(point);

                finalColor += pointColor / FIDELITY;
            }

            gl_FragColor = finalColor;
        // PARSER CONDITION END
        // PARSER CONDITION / self.webglSmoothingStyle == Triangles.WEBGL_SMOOTHING_STYLE_FULL
            vec4 finalColor = vec4(0, 0, 0, 0);
            float squaredFidelity = pow(FIDELITY, 2.0);

            for (float i = .0; i < FIDELITY; i++)
            {
                for (float j = .0; j < FIDELITY; j++)
                {
                    vec2 point = vec2(canvasPosition);

                    if (i > .0) point.x += i / (canvasResolution.x / 2.0) / FIDELITY;
                    if (j > .0) point.y += j / (canvasResolution.y / 2.0) / FIDELITY;

                    vec4 pointColor = processPixel(point);

                    finalColor += pointColor / squaredFidelity;
                }
            }

            gl_FragColor = finalColor;
        // PARSER CONDITION END
    // PARSER CONDITION END
}


/*


function compileShader(e, t, n) {
    var o = e.createShader(n);
    if (e.shaderSource(o, t), e.compileShader(o), !e.getShaderParameter(o, e.COMPILE_STATUS)) throw "could not compile shader:" + e.getShaderInfoLog(o);
    return o
}

function createProgram(e, t, n) {
    var o = e.createProgram();
    if (e.attachShader(o, t), e.attachShader(o, n), e.linkProgram(o), !e.getProgramParameter(o, e.LINK_STATUS)) throw "program filed to link:" + e.getProgramInfoLog(o);
    return o
}

function createShaderFromScriptTag(e, t, n) {
    var o = document.getElementById(t);
    if (!o) throw "*** Error: unknown script element" + t;
    var a = o.text;
    if (!n)
        if ("x-shader/x-vertex" == o.type) n = e.VERTEX_SHADER;
        else if ("x-shader/x-fragment" == o.type) n = e.FRAGMENT_SHADER;
    else if (!n) throw "*** Error: shader type not set";
    return compileShader(e, a, n)
}

function createProgramFromScripts(e, t, n) {
    return createProgram(e, createShaderFromScriptTag(e, t), createShaderFromScriptTag(e, n))
}

function setPixelRatio() {
    pixelRatio = 1, void 0 !== window.screen.systemXDPI && void 0 !== window.screen.logicalXDPI ? pixelRatio = window.screen.systemXDPI / window.screen.logicalXDPI : void 0 !== window.devicePixelRatio && (pixelRatio = window.devicePixelRatio)
}! function() {
    for (var e = 0, t = ["ms", "moz", "webkit", "o"], n = 0; n < t.length && !window.requestAnimationFrame; ++n) window.requestAnimationFrame = window[t[n] + "RequestAnimationFrame"], window.cancelAnimationFrame = window[t[n] + "CancelAnimationFrame"] || window[t[n] + "CancelRequestAnimationFrame"];
    window.requestAnimationFrame || (window.requestAnimationFrame = function(t, n) {
        var o = (new Date).getTime(),
            a = Math.max(0, 16 - (o - e)),
            i = window.setTimeout(function() {
                t(o + a)
            }, a);
        return e = o + a, i
    }), window.cancelAnimationFrame || (window.cancelAnimationFrame = function(e) {
        clearTimeout(e)
    })
}();
var getScrollableObject;
! function(e) {
    getScrollableObject = function(t) {
        if (!(!t.nodeName || -1 != e.inArray(t.nodeName.toLowerCase(), ["iframe", "#document", "html", "body"]))) return t;
        var n = (t.contentWindow || t).document || t.ownerDocument || t;
        return navigator.userAgent.indexOf("Safari") > -1 || "BackCompat" == n.compatMode ? n.body : n.documentElement
    }
}(jQuery),
function(e) {
    e.fn.cleanWhitespace = function() {
        return textNodes = this.contents().filter(function() {
            return 3 == this.nodeType && !/\S/.test(this.nodeValue)
        }).remove(), this
    }
}(jQuery);
var EventManager = function() {
        this.listeners = [], this.addListener = function(e, t) {
            this.listeners.hasOwnProperty(e) || (this.listeners[e] = []), this.listeners[e].push(t)
        }, this.removeListener = function(e, t) {
            if (this.listeners.hasOwnProperty(e)) {
                var n = this.listeners[e],
                    o = n.indexOf(t); - 1 != o && n.splice(o, 1)
            }
        }, this.trigger = function(e, t) {
            var n = this.listeners[e];
            if (n)
                for (var o = 0; o < n.length; o++)(0, n[o])(t)
        }
    },
    ScrollAbstract;
! function() {
    var e = navigator.userAgent.match(/(iPod|iPhone|iPad)/),
        t = navigator.userAgent.match(/(iPod|iPhone|iPad)/) && navigator.userAgent.match(/AppleWebKit/) && !navigator.userAgent.match("CriOS");
    (ScrollAbstract = function(e, t, n, o) {
        function a(e, t) {
            if (te instanceof Array) {
                var n = e;
                t && (n %= ne);
                for (var o = 0; o < te.length - 1 && Math.abs(n - te[o]) >= Math.abs(e - te[o + 1]);) o++;
                return o
            }
            var a = Math.round(e / te);
            return t && (a %= repeatedPagesCount), a
        }

        function i() {
            if (B.paging) {
                var e = a(B.currentPosition);
                e != B.currentPageIndex && (B.currentPageIndex = e, d("pageChange"))
            }
        }

        function r(e, t, n, o, a, i) {
            if (te instanceof Array) {
                e < 0 ? e = 0 : e > te.length - 1 && (e = te.length - 1), B.currentPageIndex = e;
                s = te[e]
            } else {
                var r = n ? Math.floor(B.currentPosition / ne) * B.repeatedPagesCount : 0;
                B.currentPageIndex = r + e;
                var s = B.currentPageIndex * te
            }
            m(s, t, !1, a, i, o)
        }

        function s(e, t) {
            if (G = t, z = e, Q = G <= z, K = !1, Q) switch (J) {
                case ScrollAbstract.ON_USELESS_CONTAIN:
                    H = G - z, N = 0;
                    break;
                case ScrollAbstract.ON_USELESS_FIX_TO_TOP:
                    H = N = 0;
                    break;
                case ScrollAbstract.ON_USELESS_DISABLE:
                    K = !0
            } else H = 0, N = G - z;
            B.changePagesSize(ee), B.acommodateOnUpdateDimension && M()
        }

        function l() {
            function e() {
                k = requestAnimationFrame(function() {
                    e(), u()
                })
            }
            B.speedRecordMethod == ScrollAbstract.INTERVAL_METHOD ? F = setInterval(u, B.speedRecordFrameRate > 0 ? 1e3 / B.speedRecordFrameRate : 1) : B.speedRecordMethod == ScrollAbstract.REQUEST_FRAME_METHOD && e()
        }

        function c() {
            B.speedRecordMethod == ScrollAbstract.INTERVAL_METHOD ? F && clearInterval(F) : B.speedRecordMethod == ScrollAbstract.REQUEST_FRAME_METHOD && null != k && (cancelAnimationFrame(k), k = null)
        }

        function d(e) {
            var t = N - H,
                n = z / t,
                o = B.currentPosition - H,
                a = n / t;
            o < 0 ? a -= -o / t : B.currentPosition > N && (a -= (B.currentPosition - N) / t), B.triggerEvent(e, {
                type: e,
                position: B.currentPosition,
                positionRatio: o / t,
                visibleRatio: a,
                currentPage: B.currentPageIndex,
                speed: Y
            })
        }

        function u() {
            $ && (Y = (L - $) * B.speedRecordMultiplier, L = $)
        }

        function g(e, t) {
            if (e < H) return H - (n = H - e) * t;
            if (e > N) {
                var n = e - N;
                return N + n * t
            }
            return e
        }

        function f(e) {
            return e || !B.useInfiniteFrameRate ? 1e3 / B.frameRate : 1
        }

        function m(e, t, n, o, a, i) {
            function r() {
                ae = requestAnimationFrame(function() {
                    r(), h()
                })
            }
            ie = t, re = n, S(), j && B.cancelDrag(), P();
            var s = _(!1, Z = e);
            if (s) {
                var l = O(s);
                if (l == ScrollAbstract.PREVENT_SCROLL_TO_OVERFLOW) Z = g(Z, 0);
                else if (l == ScrollAbstract.RESIST_AND_ACCOMMODATE_SCROLL_TO_OVERFLOW && !isNaN(B.maxScrollToOverflowRatio)) {
                    var c = N + B.maxScrollToOverflowRatio * z / B.overflowResistance;
                    if (Z > c) Z = c;
                    else {
                        var d = H - B.maxScrollToOverflowRatio * z / B.overflowResistance;
                        Z < d && (Z = d)
                    }
                }
            }
            if (se = o || B.scrollToAcceleration, le = a || B.scrollToDeceleration, !B.scrollingTo) {
                i || (ce = B.currentPosition), B.timeBasedAnimation && (q = (new Date).getTime());
                var u = f();
                B.frameMethod == ScrollAbstract.INTERVAL_METHOD ? oe = setInterval(h, u < 1 ? 1 : u) : B.frameMethod == ScrollAbstract.REQUEST_FRAME_METHOD && r(), B.scrollingTo = !0
            }
        }

        function h() {
            if (B.timeBasedAnimation) var e = (new Date).getTime(),
                t = (e - q) / f(!0);
            else t = 1;
            if (t > 0) {
                var n = (Z - ce) * (1 - Math.pow(1 - le, t)),
                    o = Z >= ce ? 1 : -1,
                    a = ((Y += se * t * o) >= 0 ? 1 : -1) == o;
                a && Math.abs(n / t) < Math.abs(Y) && (Y = n / t), ce += Y * t;
                var i = Math.abs(ce - Z),
                    r = C(!0),
                    s = a && i < (r ? B.scrollToMinDistanceOnResist : B.scrollToMinDistance),
                    l = s ? Z : ce,
                    c = _(!1, l);
                if (c && ((d = O(c)) != ScrollAbstract.RESIST_AND_ACCOMMODATE_SCROLL_TO_OVERFLOW || ie ? d != ScrollAbstract.PREVENT_SCROLL_TO_OVERFLOW || ie || (l = g(l, 0)) : l = g(l, B.overflowResistance)), A(l), s)
                    if (r) {
                        var d = O(c);
                        d != ScrollAbstract.ACCOMMODATE_SCROLL_TO_OVERFLOW && d != ScrollAbstract.RESIST_AND_ACCOMMODATE_SCROLL_TO_OVERFLOW || (ie ? T() : (S(), p(), B.scrollingTo = !1, M(!0)))
                    } else re && B.paging && (x() || B.accommodateToPageEvenWhenNoLimitsVisible) ? (S(), M()) : T();
                B.timeBasedAnimation && (q = e)
            }
        }

        function p() {
            B.frameMethod == ScrollAbstract.INTERVAL_METHOD ? oe && clearInterval(oe) : B.frameMethod == ScrollAbstract.REQUEST_FRAME_METHOD && null != ae && (cancelAnimationFrame(ae), ae = null)
        }

        function T() {
            B.scrollingTo && (p(), B.scrollingTo = !1, B.triggerEvent("scrollToStopped"), B.triggerEvent("scrollToComplete"))
        }

        function v() {
            B.scrollingTo && (p(), B.scrollingTo = !1, B.triggerEvent("scrollToStopped"), B.triggerEvent("scrollToCancelled"))
        }

        function S() {
            B.scrollingTo && (B.triggerEvent("scrollToStopped"), B.triggerEvent("scrollToReplaced"))
        }

        function E() {
            if (B.timeBasedAnimation && (q = (new Date).getTime()), B.releaseMode == ScrollAbstract.NORMAL_RELEASE_MODE || !B.snapToPageEvenWhenNoLimitsVisible && !x()) w();
            else if (B.releaseMode == ScrollAbstract.PAGE_SNAP_RELEASE_MODE) {
                var e = null === B.pageSnapAcceleration ? B.scrollToAcceleration : B.pageSnapAcceleration,
                    t = null === B.pageSnapDeceleration ? B.scrollToDeceleration : B.pageSnapDeceleration;
                if (Math.abs(Y) > B.pageSnapPageChangeMinSpeed) {
                    var n = a(B.pageSnapOnePageAtATime ? y : B.currentPosition) + Y / Math.abs(Y);
                    !B.repeatPages && (n < 0 || n >= te.length) ? w() : r(n, !0, !1, !0, e, t)
                } else ce = Z = B.currentPosition = B.currentPosition, r(a(B.currentPosition), !0, !1, !0, e, t)
            }
        }

        function w() {
            function e() {
                ue = requestAnimationFrame(function() {
                    e(), b()
                })
            }
            var t = f();
            B.frameMethod == ScrollAbstract.INTERVAL_METHOD ? de = setInterval(b, t < 1 ? 1 : t) : B.frameMethod == ScrollAbstract.REQUEST_FRAME_METHOD && e()
        }

        function R() {
            B.frameMethod == ScrollAbstract.INTERVAL_METHOD ? clearInterval(de) : B.frameMethod == ScrollAbstract.REQUEST_FRAME_METHOD && null != ue && (cancelAnimationFrame(ue), ue = null)
        }

        function A(e) {
            B.currentPosition = e, i(), d("update")
        }

        function b() {
            if (B.timeBasedAnimation) var e = (new Date).getTime(),
                t = (e - q) / f(!0);
            else t = 1;
            for (var n = B.currentPosition, o = 0; o < t; o++) {
                var a = t - o;
                a > 1 && (a = 1), n += (Y *= Math.pow(B.deceleration, a)) * a
            }
            var i = C(!0, n);
            if (i)
                if (B.bounces) {
                    if (Y *= Math.pow(B.bounceAdditionalDeceleration, t), null !== B.bounceMaxOverflowRatio) {
                        var r = ("min" == i ? H - n : n - N) / (z * B.bounceMaxOverflowRatio);
                        r > 1 && (r = 1, n = "min" == i ? H - z * B.bounceMaxOverflowRatio : N + z * B.bounceMaxOverflowRatio), Y *= 1 - r
                    }
                } else "min" == i ? n = H : "max" == i && (n = N), Y = 0;
            ce = Z = n, A(n), (i && Math.abs(Y) < B.minSpeedOnResist || Math.abs(Y) < B.minSpeed || B.paging && Math.abs(Y) < B.minSpeedOnPaging && (B.accommodateToPageEvenWhenNoLimitsVisible || x())) && (R(), M()), B.timeBasedAnimation && (q = e)
        }

        function C(e, t) {
            var n = _(e, t);
            if (n) {
                var o = O(n);
                if (o == ScrollAbstract.RESIST_AND_ACCOMMODATE_SCROLL_TO_OVERFLOW || o == ScrollAbstract.PREVENT_SCROLL_TO_OVERFLOW) return n
            }
            return !1
        }

        function _(e, t) {
            var n = void 0 != t && null != t ? t : B.currentPosition;
            if (n < H) {
                if (!e || Y < 0) return "min"
            } else if (n > N && (!e || Y > 0)) return "max";
            return !1
        }

        function O(e) {
            return "min" == e ? null !== B.scrollToOverflowStart ? B.scrollToOverflowStart : B.scrollToOverflow : "max" == e ? null !== B.scrollToOverflowEnd ? B.scrollToOverflowEnd : B.scrollToOverflow : void 0
        }

        function x(e) {
            var t = void 0 != e && null != e ? e : B.currentPosition;
            if (te instanceof Array) {
                for (var n = 0; n < te.length; n++) {
                    var o = te[n];
                    if (o > t && o < t + z) return !0
                }
                return !1
            }
            var a = t % te;
            return a < 0 && (a += te), 0 == a || a + z > te
        }

        function M(e) {
            var t = C(),
                n = null === B.accommodateAcceleration ? B.scrollToAcceleration : B.accommodateAcceleration,
                o = null === B.accommodateDeceleration ? B.scrollToDeceleration : B.accommodateDeceleration;
            t ? m("min" == t ? H : N, !0, !1, n, o) : B.paging && !e && (B.accommodateToPageEvenWhenNoLimitsVisible || x()) && r(a(B.currentPosition), !0, !1, !1, n, o)
        }

        function P() {
            R()
        }
        var y, D, I, L, $, H, N, F, k, U, V, W, G, z, q, B = this,
            j = !1,
            Y = 0,
            X = {},
            Q = !1,
            K = !1,
            J = ScrollAbstract.defaultOnUseless,
            Z = n || 0,
            ee = 0,
            te = 0,
            ne = 0;
        this.currentPosition = Z, this.minSpeed = ScrollAbstract.defaultMinSpeed, this.minSpeedOnResist = ScrollAbstract.defaultMinSpeedOnResist, this.scrollingTo = !1, this.scrollToMinDistance = ScrollAbstract.defaultScrollToMinDistance, this.scrollToMinDistanceOnResist = ScrollAbstract.defaultScrollToMinDistanceOnResist, this.scrollToAcceleration = ScrollAbstract.defaultScrollToAcceleration, this.scrollToDeceleration = ScrollAbstract.defaultScrollToDeceleration, this.accommodateAcceleration = null, this.accommodateDeceleration = null, this.decelerating = ScrollAbstract.defaultDecelerating, this.deceleration = ScrollAbstract.defaultDeceleration, this.bounces = ScrollAbstract.defaultBounces, this.bounceAdditionalDeceleration = ScrollAbstract.defaultBounceAdditionalDeceleration, this.bounceMaxOverflowRatio = ScrollAbstract.defaultBounceMaxOverflowRatio, this.overflowResistance = ScrollAbstract.defaultOverflowResistance, this.frameRate = ScrollAbstract.defaultFrameRate, this.timeBasedAnimation = ScrollAbstract.defaultTimeBasedAnimation, this.useInfiniteFrameRate = ScrollAbstract.defaultUseInfiniteFrameRate, this.accommodateTime = ScrollAbstract.defaultAccommodateTime, this.scrollToOverflow = ScrollAbstract.defaultScrollToOverflow, this.scrollToOverflowStart = null, this.scrollToOverflowEnd = null, this.maxScrollToOverflowRatio = ScrollAbstract.defaultMaxScrollToOverflowRatio, this.speedRecordFrameRate = ScrollAbstract.defaultSpeedRecordFrameRate, this.speedRecordMultiplier = ScrollAbstract.defaultSpeedRecordMultiplier, this.acommodateOnUpdateDimension = !0, this.correctFrameDrop = !0, this.dragging = !1, this.draggable = !0, this.dragThreshold = 0, this.paging = ScrollAbstract.defaultPaging, this.minSpeedOnPaging = ScrollAbstract.defaultMinSpeedOnPaging, this.accommodateToPageEvenWhenNoLimitsVisible = ScrollAbstract.defaultAccommodateToPageEvenWhenNoLimitsVisible, this.currentPageIndex = o || 0, this.releaseMode = ScrollAbstract.defaultReleaseMode, this.pageSnapPageChangeMinSpeed = ScrollAbstract.defaultPageSnapPageChangeMinSpeed, this.pageSnapOnePageAtATime = ScrollAbstract.defaultPageSnapOnePageAtATime, this.snapToPageEvenWhenNoLimitsVisible = ScrollAbstract.defaultSnapToPageEvenWhenNoLimitsVisible, this.pageSnapAcceleration = null, this.pageSnapDeceleration = null, this.minPage = 0, this.maxPage = Math.ceil(t / e), this.repeatPages = !1, this.repeatedPagesCount = 0, this.angleThreshold = null, this.frameMethod = ScrollAbstract.defaultFrameMethod, this.speedRecordMethod = ScrollAbstract.defaultSpeedRecordMethod, this.changePagesSize = function(e, t) {
            if (ee = e, e instanceof Array) {
                if (t) te = e;
                else {
                    te = [];
                    ne = 0, te.push(0);
                    for (var n = 0; n < e.length; n++) ne += e[n], te.push(ne)
                }
                B.minPage = te[0], B.maxPage = te[te.length - 1]
            } else te = e, B.repeatPages && (ne = te * B.repeatedPagesCount), B.minPage = 0, B.maxPage = Math.ceil(G / z);
            i()
        }, this.goToPage = function(e, t) {
            r(e, !1, t)
        }, this.nextPage = function() {
            (B.repeatPages || B.currentPageIndex < B.maxPage) && B.goToPage(B.currentPageIndex + 1)
        }, this.previousPage = function() {
            (B.repeatPages || B.currentPageIndex > B.minPage) && B.goToPage(B.currentPageIndex - 1)
        }, s(e, t), this.startDrag = function(e, t) {
            void 0 == t && (t = 0), this.draggable && !K && (P(), v(), this.dragging = j = !0, U = !1, V = !1, y = this.currentPosition, Y = 0, D = L = $ = e, I = t, this.decelerating && l(), d("dragStart"))
        }, this.updateDrag = function(e, t) {
            if (void 0 == t && (t = 0), this.draggable && j) {
                if (!U) {
                    if ((null != B.angleThreshold ? Math.sqrt(Math.pow(e - D, 2) + Math.pow(t - I, 2)) : Math.abs(e - D)) > this.dragThreshold) {
                        U = !0;
                        var n = e - D;
                        if (W = this.dragThreshold * n / Math.abs(n), null != B.angleThreshold) {
                            var o = Math.atan2(t - I, e - D);
                            (o = Math.abs(o)) > Math.PI / 2 && (o = Math.PI - o), (V = o <= B.angleThreshold) ? d("dragEffective") : (this.dragging = j = !1, c(), E(), d("dragStop"))
                        } else d("dragEffective")
                    }
                }
                if (U && (null === B.angleThreshold || V)) {
                    var a = y + D + W - ($ = e);
                    ce = a;
                    var r = C(!1, a);
                    r && (B.bounces ? a = g(a, B.overflowResistance) : "min" == r ? a = H : "max" == r && (a = N)), Z = a, A(a), i()
                }
            }
        }, this.stopDrag = function() {
            j && (this.dragging = j = !1, c(), E(), d("dragStop"))
        }, this.cancelDrag = function() {
            j && (this.dragging = j = !1, c(), d("dragStop"))
        };
        var oe, ae, ie, re, se, le, ce = n || 0;
        this.scrollTo = function(e, t, n, o) {
            m(e, !1, t, n, o)
        }, this.scrollMore = function(e, t, n, o) {
            m(Z + e, !1, t, n, o)
        }, this.updateDimensions = s, this.changeOnUselessValue = function(e) {
            J = e, s(z, G)
        }, this.updatePosition = function(e) {
            if (j) {
                var t = e - this.currentPosition;
                y += t
            }
            v(), R(), ce = Z = this.currentPosition = e, i()
        }, this.setTo = function(e) {
            if (j) {
                var t = e - this.currentPosition;
                y += t
            }
            v(), R(), ce = Z = this.currentPosition = e, Y = 0, i(), d("update")
        }, this.destroy = function() {
            X = null, P(), v()
        };
        var de, ue;
        this.accommodateNow = M, this.getScrollToDestination = function() {
            return Z
        }, this.eventManager = new EventManager, this.addEventListener = function(e, t) {
            this.eventManager.addListener(e, t)
        }, this.removeEventListener = function(e, t) {
            this.eventManager.removeListener(e, t)
        }, this.triggerEvent = function(e, t) {
            t || (t = {
                type: e
            }), this.eventManager.trigger(e, t)
        }
    }).NORMAL_DECELERATION = .9671838, ScrollAbstract.FAST_DECELERATION = .8457719, ScrollAbstract.PREVENT_SCROLL_TO_OVERFLOW = "prevent", ScrollAbstract.IGNORE_SCROLL_TO_OVERFLOW = "ignore", ScrollAbstract.RESIST_AND_ACCOMMODATE_SCROLL_TO_OVERFLOW = "resistAndAccommodate", ScrollAbstract.ACCOMMODATE_SCROLL_TO_OVERFLOW = "accommodate", ScrollAbstract.ON_USELESS_DISABLE = "disable", ScrollAbstract.ON_USELESS_CONTAIN = "contain", ScrollAbstract.ON_USELESS_FIX_TO_TOP = "fixToTop", ScrollAbstract.NORMAL_RELEASE_MODE = "normal", ScrollAbstract.PAGE_SNAP_RELEASE_MODE = "pageSnap", ScrollAbstract.INTERVAL_METHOD = "interval", ScrollAbstract.REQUEST_FRAME_METHOD = "request", ScrollAbstract.defaultMinSpeed = .01, ScrollAbstract.defaultScrollToAcceleration = 1, ScrollAbstract.defaultScrollToDeceleration = .1, ScrollAbstract.defaultMinSpeedOnResist = .01, ScrollAbstract.defaultScrollToMinDistance = .01, ScrollAbstract.defaultScrollToMinDistanceOnResist = 1, ScrollAbstract.defaultSpeedRecordFrameRate = 60, ScrollAbstract.defaultSpeedRecordMultiplier = 1, ScrollAbstract.defaultDecelerating = !0, ScrollAbstract.defaultDeceleration = e ? ScrollAbstract.FAST_DECELERATION : ScrollAbstract.NORMAL_DECELERATION, ScrollAbstract.defaultBounces = !0, ScrollAbstract.defaultOverflowResistance = .25, ScrollAbstract.defaultBounceAdditionalDeceleration = .5, ScrollAbstract.defaultBounceMaxOverflowRatio = .5, ScrollAbstract.defaultFrameRate = 60, ScrollAbstract.defaultTimeBasedAnimation = !0, ScrollAbstract.defaultUseInfiniteFrameRate = !0, ScrollAbstract.defaultScrollToOverflow = ScrollAbstract.PREVENT_SCROLL_TO_OVERFLOW, ScrollAbstract.defaultMaxScrollToOverflowRatio = NaN, ScrollAbstract.defaultOnUseless = ScrollAbstract.ON_USELESS_FIX_TO_TOP, ScrollAbstract.defaultPaging = !1, ScrollAbstract.defaultMinSpeedOnPaging = 1, ScrollAbstract.defaultAccommodateToPageEvenWhenNoLimitsVisible = !1, ScrollAbstract.defaultSnapToPageEvenWhenNoLimitsVisible = !1, ScrollAbstract.defaultReleaseMode = ScrollAbstract.NORMAL_RELEASE_MODE, ScrollAbstract.defaultPageSnapPageChangeMinSpeed = 5, ScrollAbstract.defaultPageSnapOnePageAtATime = !0, ScrollAbstract.defaultFrameMethod = ScrollAbstract.REQUEST_FRAME_METHOD, ScrollAbstract.defaultSpeedRecordMethod = t ? ScrollAbstract.INTERVAL_METHOD : ScrollAbstract.REQUEST_FRAME_METHOD
}();
var PartialCircle;
! function(e) {
    PartialCircle = function(t, n, o, a, i, r) {
        isNaN(o) && (o = 0);
        var s, l = e('\t\t<svg class="partial-circle">\t\t\t<circle fill="none" />\t\t</svg>\t'),
            c = l.children();
        l.attr("width", t), l.attr("height", t), c.attr("cx", t / 2), c.attr("cy", t / 2), a && l.addClass(a);
        var d = !1;
        this.setLengthRatio = function(e) {
            var t = s * e;
            if (t <= r) {
                if (this.cuteHide || d) {
                    c.css("stroke-width", "");
                    var n = Number(c.css("stroke-width").split("px")[0]);
                    c.css("stroke-width", n * t / r + "px"), d = !0
                }
                t = r
            } else d && (c.css("stroke-width", ""), d = !1);
            c.css("stroke-dasharray", t + "," + (s - t))
        }, this.setStartRatio = function(e) {
            e += o, c.css("stroke-dashoffset", -e * s)
        }, this.setRadius = function(e) {
            n = e, s = Math.PI * n * 2, c.attr("r", n)
        }, this.setRadius(n), this.setStartRatio(0), this.cuteHide = i, this.$svg = l
    }
}(jQuery),
function(e, t) {
    "function" == typeof define && define.amd ? define(["jquery"], t) : "object" == typeof module && module.exports ? module.exports = t(require("jquery")) : (e.Follow = t(e.jQuery), e.Follow.factory = t)
}(this, function(e) {
    var t;
    return function(e) {
        function n(t, n, o, a) {
            n.each(function() {
                var n = e(this);
                a || "top" != t || i(n), s(t, n, a), f(n), p(t, n, a)
            })
        }

        function o(t) {
            t.each(function() {
                f(e(this))
            })
        }

        function a(t, n, o) {
            n.each(function() {
                var n = e(this);
                o || r(n), o || S(t), g(n, o)
            })
        }

        function i(e) {
            "static" == e.css("position") && e.css("position", "relative")
        }

        function r(e) {
            e.css("position", "")
        }

        function s(e, t, n) {
            var o = {
                arrived: !0,
                pendingLastOffsetChanges: 0
            };
            l(t, o), c(e, t, o, n, n, n), d(t, o), u(t, o), t.data("follow-data", o)
        }

        function l(t, n) {
            n.$targetUp = null, n.$targetDown = null;
            var o = t.attr("data-follow-up-target");
            if (o) n.$targetUp = e(o);
            else {
                var a = t.data("follow-target-up");
                a && (n.$targetUp = a)
            }
            var i = t.attr("data-follow-down-target");
            if (i) n.$targetDown = e(i);
            else {
                var r = t.data("follow-target-down");
                r && (n.$targetDown = r)
            }
        }

        function c(e, t, n, o, a, i) {
            var r;
            o && (r = T(e, t), S(t));
            var s = 0;
            "top" == e && (s = Number(t.css("top").split("px")[0]) || 0), n.naturalTop = s, a || (n.currentTop = s), i && (n.currentTop = t.data("suspended-top")), o && v(e, t, r)
        }

        function d(e, t) {
            (t || e.data("follow-data")).easing = Number(e.attr("follow-easing"))
        }

        function u(e, n) {
            var o = n || e.data("follow-data"),
                a = Number(e.attr("data-follow-direction-change-mode"));
            o.directionChangeMode = isNaN(a) ? t.DIRECTION_CHANGE_MODE_NORMAL : a
        }

        function g(e, t) {
            if (t) {
                var n = e.data("follow-data");
                e.data("suspended-top", n.currentTop), e.data("suspended-arrived", n.arrived)
            }
            e.removeData("follow-data")
        }

        function f(e, t) {
            var n = t || e.data("follow-data");
            n.lastOffsetTop = e.offset().top, n.pendingLastOffsetChanges = 0
        }

        function m(e, t, n) {
            (t || e.data("follow-data")).pendingLastOffsetChanges += n
        }

        function h(e, t) {
            var n = t || e.data("follow-data");
            n.lastOffsetTop += n.pendingLastOffsetChanges, n.pendingLastOffsetChanges = 0
        }

        function p(e, t, n) {
            var o, a = t.data("follow-data");
            if (n && (o = T(e, t), S(t)), a.$targetUp) {
                var i;
                n && (i = T(e, a.$targetUp), S(a.$targetUp)), a.diffUp = t.offset().top - a.$targetUp.offset().top, n && v(e, a.$targetUp, i)
            }
            if (a.$targetDown) {
                var r;
                n && (r = T(e, a.$targetDown), S(a.$targetDown)), a.diffDown = t.offset().top - a.$targetDown.offset().top, n && v(e, a.$targetDown, r)
            }
            n && v(e, t, o)
        }

        function T(e, t) {
            return "top" != e ? parseFloat(t.css("transform").split("(")[1]) : t.css("top", "")
        }

        function v(e, t, n) {
            "top" != e ? t.css("transform", "translateY(" + n + "px)") : t.css("top", n)
        }

        function S(e) {
            "top" != effectMode ? e.css("transform", "") : e.css("top", "")
        }
        var E = 1e3 / 60;
        (t = function(i, r) {
            function s() {
                S && C.length ? l() : c()
            }

            function l() {
                null === b && (cancelAnimationFrame(b), b = requestAnimationFrame(d), "scroll" == i && (_ = getScroll()), O = (new Date).getTime())
            }

            function c() {
                null !== b && (cancelAnimationFrame(b), b = null, _ = null)
            }

            function d(e) {
                b = requestAnimationFrame(d), g()
            }

            function u(e, t, n) {
                var o = (t - e) / E;
                return 1 - Math.pow(1 - n, o)
            }

            function g(n) {
                var o = (new Date).getTime();
                if ("scroll" == i) {
                    var a = getScroll(),
                        s = a - _;
                    0 != s && (p.offset(r, s, !0), C.each(function() {
                        m(e(this), null, -s)
                    }), R || (w = s > 0)), _ = a
                } else if ("offset" == i) {
                    var l = (c = C.eq(0)).data("follow-data").lastOffsetTop - c.offset().top;
                    0 != l && (p.offset(r, l, !0), C.each(function() {
                        m(e(this), null, -l)
                    }), R || (w = l > 0))
                }
                if (w ? C.each(function(a) {
                        var i, s, l = e(this),
                            c = l.data("follow-data");
                        if (c.$targetUp && c.lastOffsetTop > p.ignoreTargetsBelowTop) {
                            var d = c.$targetUp.data("follow-data");
                            i = c.naturalTop + d.currentTop - d.naturalTop, s = c.easing, c.directionChangeMode != t.DIRECTION_CHANGE_MODE_NORMAL && i - c.currentTop > 0 && (c.directionChangeMode == t.DIRECTION_CHANGE_MODE_SEEK_NATURAL ? i = c.naturalTop : c.directionChangeMode == t.DIRECTION_CHANGE_MODE_PUSH && (s = 1))
                        } else i = c.naturalTop, s = c.easing;
                        n || (s = u(O, o, s));
                        var g = (i - c.currentTop) * s;
                        c.currentTop += g, v(r, l, c.currentTop), f(l, c), m(l, c, g), h(l, c)
                    }) : A.each(function() {
                        var a, i, s = e(this),
                            l = s.data("follow-data");
                        if (l.$targetDown && l.lastOffsetTop < viewportHeight + p.ignoreTargetsAboveTop) {
                            var c = l.$targetDown.data("follow-data");
                            a = l.naturalTop + c.currentTop - c.naturalTop, i = l.easing, l.directionChangeMode != t.DIRECTION_CHANGE_MODE_NORMAL && a - l.currentTop < 0 && (l.directionChangeMode == t.DIRECTION_CHANGE_MODE_SEEK_NATURAL ? a = l.naturalTop : l.directionChangeMode == t.DIRECTION_CHANGE_MODE_PUSH && (i = 1))
                        } else a = l.naturalTop, i = l.easing;
                        n || (i = u(O, o, i));
                        var d = (a - l.currentTop) * i;
                        l.currentTop += d, v(r, s, l.currentTop), f(s, l), m(s, l, d), h(s, l)
                    }), "offset" == i) {
                    var c = C.eq(0);
                    c.data("follow-data").lastOffsetTop = c.offset().top
                }
                T.trigger("followUpdate"), O = o
            }

            function f(e, n, o) {
                if (p.arriveMode != t.ARRIVE_MODE_NONE) {
                    var a = n.currentTop - n.naturalTop,
                        i = !1;
                    n.arrived ? p.arriveMode == t.ARRIVE_MODE_UP ? a > p.arrivedThreshold && (i = !0) : p.arriveMode == t.ARRIVE_MODE_DOWN ? a < -p.arrivedThreshold && (i = !0) : p.arriveMode == t.ARRIVE_MODE_BOTH_DIRECTIONS && Math.abs(a) > p.arrivedThreshold && (i = !0) : p.arriveMode == t.ARRIVE_MODE_UP ? a <= p.arrivedThreshold && (i = !0) : p.arriveMode == t.ARRIVE_MODE_DOWN ? a >= -p.arrivedThreshold && (i = !0) : p.arriveMode == t.ARRIVE_MODE_BOTH_DIRECTIONS && Math.abs(a) <= p.arrivedThreshold && (i = !0), i && (n.arrived = !n.arrived, o || e.trigger(n.arrived ? "arrived" : "left"))
                }
            }
            var p = this,
                T = e(this);
            this.$follow = T;
            var S = !1;
            this.enable = function() {
                S || (S = !0, o(C), s())
            }, this.disable = function() {
                S && (S = !1, s())
            }, this.ignoreTargetsBelowTop = -500, this.ignoreTargetsAboveTop = 500, this.arrivedThreshold = .01, this.arriveMode = t.ARRIVE_MODE_NONE;
            var w = !0,
                R = !1;
            this.setForcedDirection = function(e) {
                R = !0, w = e
            }, this.clearForcedDirection = function(e) {
                R = !1
            };
            var A, b = null,
                C = e();
            this.add = function(o, a, l, c) {
                if (n(r, o, i, l), C = a ? o.add(C) : C.add(o), A = e(C.get().reverse()), C.length > o.length && !c)
                    if (a) {
                        var d = C.eq(o.length);
                        t.rereadAndUpdate(r, d)
                    } else {
                        var u = C.eq(C.length - o.length - 1);
                        t.rereadAndUpdate(r, u)
                    }
                s()
            }, this.remove = function(t, n) {
                a(r, t, n), C = C.not(t), A = e(C.get().reverse()), s()
            };
            var _ = null,
                O = null;
            this.update = function() {
                g(!0)
            }, this.offset = function(e, n, o) {
                t.offset(e, C, n, o)
            }
        }).rereadAndUpdate = function(t, n) {
            n.each(function() {
                var n = e(this),
                    o = n.data("follow-data");
                l(n, o), c(t, n, o, !0, !0, !1), d(n, o), u(n, o), p(t, n, !0)
            })
        }, t.offset = function(t, n, o, a) {
            n.each(function() {
                var n = e(this),
                    i = n.data("follow-data");
                i.currentTop += o, v(t, n, i.currentTop), m(n, i, o), a || h(n, i)
            })
        }, t.setContiguousTargets = function(e) {
            t.setContiguousTargetsUp(e), t.setContiguousTargetsDown(e)
        }, t.setContiguousTargetsUp = function(e) {
            for (var t = 1; t < e.length; t++) e.eq(t).data("follow-target-up", e.eq(t - 1))
        }, t.setContiguousTargetsDown = function(e) {
            for (var t = 0; t < e.length - 1; t++) e.eq(t).data("follow-target-down", e.eq(t + 1))
        }, t.clearTargets = function(e) {
            t.clearTargetsUp(e), t.clearTargetsDown(e)
        }, t.clearTargetsUp = function(e) {
            e.removeData("follow-target-up")
        }, t.clearTargetsDown = function(e) {
            e.removeData("follow-target-down")
        }, t.readFollowEasing = function(t) {
            t.each(function() {
                d(e(this))
            })
        }, t.readDirectionChangeMode = function(t) {
            t.each(function() {
                u(e(this))
            })
        }, t.setArrivedStatus = function(t, n) {
            t.each(function() {
                e(this).data("follow-data").arrived = n
            })
        }, t.DIRECTION_CHANGE_MODE_NORMAL = 0, t.DIRECTION_CHANGE_MODE_SEEK_NATURAL = 1, t.DIRECTION_CHANGE_MODE_PUSH = 2, t.ARRIVE_MODE_NONE = 0, t.ARRIVE_MODE_BOTH_DIRECTIONS = 1, t.ARRIVE_MODE_UP = 2, t.ARRIVE_MODE_DOWN = 3
    }(e), t
});
var DeepLinks = {};
! function(e) {
    function t() {
        DeepLinks.hashHandler && DeepLinks.hashHandler()
    }
    DeepLinks.init = function() {
        $window.on("popstate", t)
    }, DeepLinks.hashHandler = null, DeepLinks.setHash = function(e) {
        history.replaceState(null, null, "#" + e)
    }, DeepLinks.addHash = function(e) {
        history.pushState(null, null, "#" + e)
    }, DeepLinks.jumpToHash = function(e) {
        history.replaceState(null, null, "#" + e), t()
    }, DeepLinks.navigateToHash = function(e) {
        history.pushState(null, null, "#" + e), t()
    }
}(jQuery);
var Spinner;
! function(e) {
    function t() {
        return new PartialCircle(68, 27, -.25, null, !1, 3)
    }

    function n(e, t, o) {
        var a = this;
        this.startRatio = e || 0, this.lengthRatio = t || 0, this.endRatio = o || 0, this.updateStart = function() {
            a.startRatio = a.endRatio - a.lengthRatio
        }, this.updateLength = function() {
            a.lengthRatio = a.endRatio - a.startRatio
        }, this.updateEnd = function() {
            a.endRatio = a.startRatio + a.lengthRatio
        }, this.minimize = function() {
            for (; this.startRatio >= 1;) this.startRatio -= 1, this.endRatio -= 1
        }, this.splitDouble = function(e, t) {
            var o = e || new n,
                a = t || new n;
            this.startRatio <= 1 ? (o.startRatio = this.startRatio, this.endRatio <= 1 ? (o.endRatio = this.endRatio, a.startRatio = 0, a.endRatio = 0) : (o.endRatio = 1, a.startRatio = 0, a.endRatio = this.endRatio - 1)) : (o.startRatio = 0, o.endRatio = 0, a.startRatio = this.startRatio - 1, a.endRatio = this.endRatio - 1), o.updateLength(), a.updateLength()
        }
    }

    function o(e) {
        for (var t = [], o = 0; o < e; o++) t.push(new n);
        return t
    }

    function a(n) {
        for (var o = e('<div class="main-spinner circular" />'), a = [], i = 0; i < n; i++) {
            var r = t();
            o.append(r.$svg), a.push(r)
        }
        this.$element = o, this.partialCircles = a, this.drawLines = function(e) {
            for (var t = 0; t < e.length; t++) {
                var n = e[t],
                    o = a[t];
                o.setStartRatio(n.startRatio), o.setLengthRatio(n.lengthRatio)
            }
        }
    }

    function i(e) {
        function t() {
            l = requestAnimationFrame(n)
        }

        function n() {
            i.draw(), t()
        }
        e || (e = 1);
        var i = this,
            r = o(e),
            s = new a(e);
        this.lines = r, 1 == e && (this.line = r[0]), this.$element = s.$element, this.draw = function() {
            s.drawLines(r)
        };
        var l;
        this.start = function() {
            t()
        }, this.stop = function() {
            cancelAnimationFrame(l)
        }
    }
    Spinner = function() {
        function e() {
            a ? (o.line.startRatio = 0, o.line.lengthRatio = 0, o.line.endRatio = 0, TweenMax.to(o.line, 2, {
                endRatio: 2,
                ease: Power2.easeInOut,
                onUpdate: t
            }), n = TweenMax.to(o.line, 2, {
                delay: .2,
                startRatio: 2,
                ease: Power2.easeInOut,
                onUpdate: t,
                onComplete: e
            })) : (o.stop(), o.$element.remove(), n = null)
        }

        function t() {
            o.line.updateLength()
        }
        var n, o = new i(1),
            a = !0;
        this.$element = o.$element, o.start(), e(), this.stop = function() {
            a = !1
        }
    }
}(jQuery);
var DEVICE_TYPE_DESKTOP = "desktop",
    DEVICE_TYPE_TABLET = "tablet",
    DEVICE_TYPE_PHONE = "phone",
    ORIENTATION_LANDSCAPE = 0,
    ORIENTATION_PORTRAIT = 1,
    ENTRANCE_DURATION = 3,
    USER_AGENT_LOWERCASE = navigator.userAgent.toLowerCase(),
    IS_MAC = -1 != USER_AGENT_LOWERCASE.indexOf("mac"),
    IS_CHROME = USER_AGENT_LOWERCASE.indexOf("chrome") > -1 || navigator.userAgent.indexOf("CriOS") > -1,
    IS_SAFARI = -1 != USER_AGENT_LOWERCASE.indexOf("safari") && -1 == USER_AGENT_LOWERCASE.indexOf("chrome"),
    IS_SAFARI_7 = -1 != navigator.userAgent.indexOf("Version/7.0 Safari"),
    FOLLOW_ENABLED = DEVICE_TYPE == DEVICE_TYPE_DESKTOP,
    FOLLOW_EFFECT_MODE = "transform";
FOLLOW_ENABLED = !1;
var $window = $(window),
    scrollableObject, $scrollableObject, $html, $body, $wrapper, $logo, $sectionsContainer, $sectionsOffsetter, $sectionsOffsetterShadow, $sectionsCropper, $sections, $sectionsFader, $footer, $footerContent, viewportHeight, pixelRatio;
setPixelRatio(),
    function(e) {
        function t() {
            scrollableObject = getScrollableObject(window), $scrollableObject = e(scrollableObject), $html = e("html"), $body = e("body"), $wrapper = e("#wrapper"), $logo = e("#logo"), $sectionsContainer = e("#sections-container"), $sectionsOffsetter = e("#sections-offsetter"), $sectionsOffsetterShadow = $sectionsOffsetter.children(".shadow"), $sectionsCropper = e("#sections-cropper"), $sections = e("#sections-container section"), $footer = e("#footer"), $footerContent = $footer.children(".content"), $window.resize(n), n()
        }

        function n() {
            viewportHeight = o(), setPixelRatio()
        }

        function o() {
            var e;
            return $body.css("height", 2e3), e = window.innerHeight, $body.css("height", ""), e
        }
        e(t)
    }(jQuery);
var Sounds = {};
! function(e) {
    Sounds.init = function() {}, Sounds.unmuteAmbient = function() {}, Sounds.muteAmbient = function() {};
    Sounds.page = function() {}, Sounds.sectionEntrance = function() {}
}(jQuery);
var Engine = {};
! function(e) {
    function t() {
        Sounds.unmuteAmbient(), $sectionsOffsetterShadow.removeClass("hidden"), $footer.removeClass("hidden"), Ve = He ? Q.slice(0, Ae + 1) : Q.slice(0, 5), w($sections.eq(0)), TweenMax.to(We, ENTRANCE_DURATION, {
            ratio: 1,
            ease: Power3.easeInOut,
            onUpdate: n,
            onComplete: o
        })
    }

    function n() {
        for (var t = 0; t < Ve.length; t++) {
            var n = Ve[t];
            if (null != n) {
                var o = e(n),
                    a = t == Ve.length - 1 ? 0 : Ne,
                    i = We.ratio * Ve.length - (Ve.length - 1 - t);
                if (i += a, (i /= 1 + a) > 0) {
                    o.data("hidden") && (o.data("hidden", !1), o.removeClass("hidden")), i > 1 && (i = 1);
                    var r = -j - ye;
                    k(o, r + (t * be - r) * i), 1 == i && (Ve[t] = null)
                }
            }
        }
    }

    function o() {
        $sections.removeClass("hidden"), $sections.data("hidden", !1), v(0, !0), E($sections.eq(0)), $window.on("mousewheel", T), $window.off("touchstart", s), $window.off("touchmove", s), $window.off("touchend", s), $window.on("touchstart", g), $window.on("touchmove", f), $window.on("touchend", m), $window.on("keydown", p), Ue = Te, DeepLinks.init(), DeepLinks.hashHandler = a, DeepLinks.hashHandler()
    }

    function a() {
        var e = r(location.hash);
        if (e != Ge) {
            for (var t = "", n = 0; n < $sections.length; n++)
                if ($sections.eq(n).hasClass("section-" + e)) {
                    t = e;
                    break
                }
            qe = t, Ge = e, Ue != Se && Ue != Te || i()
        }
    }

    function i() {
        if (ze != qe)
            if (Ue == Te) {
                var e = X[qe];
                le.currentPageIndex % $sections.length != e ? le.goToPage(e, !0) : C($sections.eq(e))
            } else Ue == Se && $()
    }

    function r(e) {
        return e.replace(/^(?:(?:#)?\/)?(.*)(?:\/)?$/, "$1")
    }

    function s(e) {
        e.preventDefault()
    }

    function l() {
        Sounds.page(), le.nextPage()
    }

    function c() {
        Sounds.page(), le.previousPage()
    }

    function d() {
        for (var t = 0; t < Q.length; t++) {
            var n = e(Q[t]);
            TweenMax.killTweensOf(n)
        }
        o()
    }

    function u(e) {
        var t = le.currentPageIndex % $sections.length,
            n = $sections.eq(t);
        n.is(Be) || (Be && A(Be), E(Be = n)), $body.removeClass("moving-pages"), i()
    }

    function g(e) {
        if (!Ke) {
            switch (Ue) {
                case Te:
                case Se:
                    var t = Ue == Te ? le : ce;
                    t.startDrag(z(e.originalEvent), G(e.originalEvent)), Je = !0, Ze = t
            }
            Ke = !0
        }
    }

    function f(e) {
        e.preventDefault(), Je && Ze.updateDrag(z(e.originalEvent), G(e.originalEvent))
    }

    function m(e) {
        0 == e.originalEvent.touches.length && (Je && (Ze.stopDrag(), Je = !1), Ke = !1)
    }

    function h() {
        Je && (Ze.stopDrag(), Je = !1)
    }

    function p(e) {
        switch (Ue) {
            case Te:
                switch (e.keyCode) {
                    case 38:
                    case 33:
                        c();
                        break;
                    case 40:
                    case 34:
                        l();
                        break;
                    case 13:
                        var t = Math.round(le.currentPosition / j) % $sections.length;
                        $sections.eq(t).find(".view-more-btn").trigger("tapone")
                }
                break;
            case Se:
                switch (e.keyCode) {
                    case 27:
                        L();
                        break;
                    case 36:
                        ce.currentPosition <= 10 ? L() : ce.scrollTo(0);
                        break;
                    case 35:
                        ce.scrollTo(K.find(".content").innerHeight() - viewportHeight);
                        break;
                    case 38:
                        ce.scrollMore(-120);
                        break;
                    case 40:
                        ce.scrollMore(120);
                        break;
                    case 33:
                        ce.currentPosition <= 10 ? L() : ce.scrollMore(.85 * -viewportHeight);
                        break;
                    case 34:
                        ce.scrollMore(.85 * viewportHeight)
                }
        }
    }

    function T(e, t) {
        if (e.preventDefault(), Ue == Te)
            if (Ce) nt || (nt = !0, Xe = 0, le.startDrag(Xe)), Xe += t, le.updateDrag(Xe), Qe && clearInterval(Qe), Qe = setTimeout(function() {
                nt = !1, le.stopDrag()
            }, 200);
            else {
                var n = t / Math.abs(t);
                if (!et || tt != n) {
                    t > 0 ? c() : l(), tt = n;
                    Ye && clearInterval(Ye), Ye = setTimeout(function() {
                        et = !1
                    }, 1250)
                }
                et = !0, je && clearInterval(je), je = setTimeout(function() {
                    et = !1
                }, _e)
            }
        else if (Ue == Se) {
            var o = -e.deltaY * e.deltaFactor;
            ce.scrollMore(o)
        }
    }

    function v(t, n) {
        if (Ue == Te || n) {
            var o = t - ot;
            o /= Math.abs(o), ot = t;
            var a = t / j,
                i = Math.floor(t / j),
                r = i % $sections.length;
            r < 0 && (r += $sections.length);
            var s = $sections.eq(r),
                l = t % j;
            l < 0 && (l += j);
            var c = l / j,
                d = (r + 1) % $sections.length,
                u = $sections.eq(d),
                g = r - 1;
            if (g < 0 && (g += $sections.length), $previousSection = $sections.eq(g), o > 0 ? c > .3 && (R(s), w(u)) : o < 0 && c <= .3 && (R(u), w(s)), a == i && A(u), A($previousSection), k(s, -l), Fe) {
                var f = s.data("$offsetter"),
                    m = (r + 1) % $sections.length,
                    h = $sections.eq(m).data("$offsetter");
                f.css({
                    transform: U(0)
                }), h.css({
                    transform: U(ke * (1 - l / j))
                }), Y.not(f).not(h).css({
                    transform: U(ke)
                })
            }
            var p = j - l;
            switch (we) {
                case ge:
                    v = 0;
                    (T = p < be) && (v = 1 - p / be);
                    break;
                case me:
                    v = 0;
                    (T = l > 0) && (v = l / be) > 1 && (v = 1);
                    break;
                case de:
                    v = 0;
                    (T = !0) && (v = l / j);
                    break;
                case ue:
                    v = 0;
                    (T = p < Re * j) && (v = 1 - p / (Re * j));
                    break;
                case fe:
                    var T = l > 0,
                        v = 0;
                    T && (v = l / (Re * j)) > 1 && (v = 1)
            }
            b(s, p / (Pe * j)), Q = (Q = []).concat($sections.slice(r).get()), Q = Q.concat($sections.slice(0, r).get()), s.css("z-index", 1e7 - i);
            var E = Math.floor(t / (j * $sections.length));
            S(s, E);
            for (var C = 1; C < Q.length; C++) {
                var _ = e(Q[C]);
                _.css("z-index", 1e7 - i - C), C < Ae + 2 && (k(_, C * be - v * be), b(_, 1));
                var O = E;
                r + C >= $sections.length && O++, S(_, O)
            }
        }
    }

    function S(e, t) {
        e.data("cycle") != t && (e.trigger("cycleChange", {
            newCycle: t
        }), e.data("cycle", t))
    }

    function E(e) {
        "entered" != e.data("visibilityState") && (e.trigger("entered"), e.data("visibilityState", "entered"))
    }

    function w(e) {
        "showing" != e.data("visibilityState") && (e.trigger("showing"), e.data("visibilityState", "showing"))
    }

    function R(e) {
        "hiding" != e.data("visibilityState") && (e.trigger("hiding"), e.data("visibilityState", "hiding"))
    }

    function A(e) {
        "hidden" != e.data("visibilityState") && (e.trigger("hidden"), e.data("visibilityState", "hidden"))
    }

    function b(e, t) {
        if (De)
            if (Me == he) e.data("$shadow").css("opacity", .999), e.data("$shadow").css("opacity", .999 * t);
            else if (Me == pe) {
            var n = 1 - t;
            n < 0 && (n = 0), e.data("$shadow").css("bottom", ye * n - ye)
        }
    }

    function C(e) {
        Ue == Te && (Ue = ve, K = e, ze = e.data("sectionName"), K.trigger("opening"), J = e.children(".internal-cropper").children(".content"), ee = e.find(".detail-page-controls"), (te = e.find(".breadcrumb.vertical")).removeClass("hidden"), te.css("bottom", viewportHeight), Z = J.find(".abduct"), setTimeout(function() {
            $window.width() < 680 ? te.css("top", viewportHeight / 2 - te.width() / 2) : te.css("top", viewportHeight / 2 + te.width() / 2)
        }, 100), ne = ee.find(".back-to-top-button"), oe = !1, ae = !1, h(), _(), O())
    }

    function _() {
        le.setTo(le.currentPosition)
    }

    function O() {
        Sounds.muteAmbient(), Sounds.sectionEntrance(), $sectionsContainer.addClass("section-opened"), K.removeClass("closed"), K.addClass("opening"), K.find(".cover").height(j);
        var t = Q.indexOf(K[0]);
        ie = e(Q.slice(0, t)), (re = e(Q.slice(t + 1, t + 1 + Ae))).eq(re.length - 1).data("$shadow").addClass("hidden"), (se = e(Q.slice(t + Ae + 1))).addClass("hidden").data("hidden", !0), q(ie), TweenMax.to(ie, Le, {
            transform: U(-j),
            ease: Power2.easeInOut
        });
        var n = parseFloat($sectionsContainer.css("bottom")) + Ae * be;
        re.each(function(t) {
            var o = e(this);
            q(o), TweenMax.to(o, Le, {
                transform: U(n + t * be),
                delay: (Ae - 1 - t) * $e,
                ease: Power2.easeInOut
            })
        }), q(K), TweenMax.to(K, Ie, {
            transform: U(-j),
            height: j + viewportHeight + 1,
            delay: Ae * $e,
            ease: Power2.easeInOut,
            onUpdate: I,
            onComplete: x
        }), K.trigger("opening-animation")
    }

    function x() {
        M(), K.data("$shadow").addClass("hidden"), K.removeClass("opening"), K.addClass("opened"), K.trigger("opened"), Ue = Se, i()
    }

    function M() {
        P(), $body.addClass("content-mode"), $sections.not(K).css("visibility", "hidden")
    }

    function P() {
        (ce = new ScrollAbstract(viewportHeight, K.find(".content").innerHeight())).scrollToAcceleration = 3, ce.scrollToDeceleration = .1, ce.overflowResistance = xe, ce.maxScrollToOverflowRatio = Oe, ce.scrollToOverflowStart = ScrollAbstract.RESIST_AND_ACCOMMODATE_SCROLL_TO_OVERFLOW, ce.scrollToOverflowEnd = ScrollAbstract.PREVENT_SCROLL_TO_OVERFLOW, ce.addEventListener("update", y)
    }

    function y(e) {
        k(K, -j - e.position), e.position < -(viewportHeight * ce.maxScrollToOverflowRatio - 1) && DeepLinks.navigateToHash("/"), D(e.position)
    }

    function D(e) {
        oe ? e < 0 && (oe = !1, ee.removeClass("fixed"), J.prepend(ee), te.removeClass("fixed"), J.prepend(te)) : e > 0 && (oe = !0, ee.addClass("fixed"), $wrapper.prepend(ee), te.addClass("fixed"), $wrapper.prepend(te)), ae ? e <= 50 && (ae = !1, ne.addClass("hidden")) : e > 150 && (ae = !0, setTimeout(function() {
            ne.removeClass("hidden")
        }, 1e3)), I()
    }

    function I() {
        var t = 0;
        Z.each(function() {
            var n = e(this),
                o = n.offset().top;
            n.hasClass("abducted") ? o > viewportHeight && n.removeClass("abducted") : o < viewportHeight - 50 && (n.css("transition-delay", .12 * t + "s, " + .12 * t++ + "s"), n.addClass("abducted"))
        })
    }

    function L() {
        Ue == Se && DeepLinks.navigateToHash("/")
    }

    function $() {
        Ue == Se && (Ue = Ee, ze = "", K.trigger("closing"), K.data("$shadow").removeClass("hidden"), K.removeClass("opened"), K.addClass("closing"), h(), ce.destroy(), ce = null, H())
    }

    function H() {
        $body.removeClass("content-mode"), $sections.not(K).css("visibility", ""), N()
    }

    function N() {
        Sounds.unmuteAmbient(), Sounds.sectionEntrance(), K.height(-K.offset().top + viewportHeight + 1), q(K), TweenMax.to(K, Ie, {
            transform: U(0),
            height: j,
            ease: Power2.easeInOut,
            onUpdate: function() {
                D(-J.offset().top)
            }
        }), re.each(function(t) {
            var n = e(this);
            q(n), TweenMax.to(n, Le, {
                transform: U((t + 1) * be),
                delay: (t + 5) * $e,
                ease: Power2.easeInOut,
                onComplete: t == re.length - 1 ? F : null
            })
        })
    }

    function F() {
        se.removeClass("hidden").data("hidden", !1), re.eq(re.length - 1).data("$shadow").removeClass("hidden"), K.find(".cover").css("height", ""), $sectionsContainer.removeClass("section-opened"), K.removeClass("closing"), K.addClass("closed"), K.trigger("closed"), Ue = Te, i()
    }

    function k(e, t) {
        e.css("transform", U(t))
    }

    function U(e) {
        return "translateY(" + e + "px)"
    }

    function V() {
        q($sectionsOffsetter), TweenMax.to($sectionsOffsetter, .5, {
            transform: U(-$footerContent.height()),
            ease: Power2.easeInOut
        }), $sectionsFader.css("display", "block"), TweenMax.to($sectionsFader, .5, {
            opacity: 1,
            ease: Power2.easeInOut
        })
    }

    function W() {
        q($sectionsOffsetter), TweenMax.to($sectionsOffsetter, .5, {
            transform: U(0),
            ease: Power2.easeInOut
        }), TweenMax.to($sectionsFader, .5, {
            opacity: 0,
            ease: Power2.easeInOut,
            onComplete: function() {
                $sectionsFader.css("display", "")
            }
        })
    }

    function G(e) {
        for (var t = 0, n = 0; n < e.touches.length; n++) t += e.touches[n].clientX;
        return touchPos = t / e.touches.length, touchPos
    }

    function z(e) {
        for (var t = 0, n = 0; n < e.touches.length; n++) t += e.touches[n].clientY;
        return touchPos = t / e.touches.length, touchPos
    }

    function q(e) {
        var t = e.css("transform");
        TweenMax.set(e, {
            clearProps: "transform"
        }), e.css("transform", t)
    }
    var B, j, Y, X, Q, K, J, Z, ee, te, ne, oe, ae, ie, re, se, le, ce, de = 0,
        ue = 1,
        ge = 2,
        fe = 3,
        me = 4,
        he = 0,
        pe = 1,
        Te = 2,
        ve = 3,
        Se = 4,
        Ee = 5,
        we = (DEVICE_TYPE, fe),
        Re = .1,
        Ae = 3,
        be = 13,
        Ce = !1,
        _e = 250,
        Oe = .25,
        xe = 1 / 3,
        Me = pe,
        Pe = DEVICE_TYPE == DEVICE_TYPE_PHONE ? .02 : .1,
        ye = 16,
        De = !0,
        Ie = 1,
        Le = .7,
        $e = .08,
        He = !0,
        Ne = .5,
        Fe = !1,
        ke = 60,
        Ue = 0;
    Engine.init = function() {
        Sounds.init(), X = [], $sections.each(function(t) {
            var n = e(this),
                o = n.attr("class").match(/section-([\w-]+?)[\s$]/i)[1];
            X[o] = t, n.data("sectionName", o)
        }), Fe && (Y = $sections.find("offsetter"));
        var t = e("#wrapper > .common-logo").remove().css("visibility", "");
        $sections.each(function(n) {
            if (n > 0) {
                var o = e(this),
                    a = t.clone(),
                    i = o.attr("class").split("section-")[1].split(" ")[0];
                a.attr("data-section", i), a.on("tapone", function() {
                    le.goToPage(0, !0)
                }), o.find(".offsetter > .content-wrapper").prepend(a)
            }
        }), t = null, $sections.each(function() {
            var t = e(this),
                n = e('<div class="shadow" />');
            t.append(n)
        }), $sections.each(function() {
            var t = e(this);
            t.data("$offsetter", t.find(".offsetter")), t.data("$shadow", t.children(".shadow"))
        }), $sections.each(function(t) {
            function n(t) {
                le.goToPage(e(t).data("index"), !0)
            }
            $section = e(this);
            var o = e('<div class="bullets-container" />'),
                a = e(),
                i = $section.attr("class").split("section-")[1].split(" ")[0];
            o.attr("data-section", i);
            for (var r = 0; r < $sections.length; r++) {
                var s = e('<div class="bullet"><div class="sprite" /></div>');
                s.data("index", r), t == r && s.addClass("current"), o.append(s), a = a.add(s)
            }
            a.on("tapone", function() {
                n(this)
            }), o.css("margin-top", -30 * $sections.length / 2), $section.find(".offsetter").prepend(o)
        });
        var n = e(".detail-page-controls").remove().css("display", "");
        $sections.each(function() {
            var t = e(this),
                o = n.clone(),
                a = t.attr("class").split("section-")[1].split(" ")[0];
            o.find(".back-to-top-button").on("tapone", function() {
                ce.scrollTo(0)
            }), o.find(".close-button").on("tapone", L), o.attr("data-section", a), t.children(".internal-cropper").children(".content").prepend(o)
        }), (le = new ScrollAbstract(1, 2)).scrollToMinDistance = 1 / pixelRatio / 2, le.dragThreshold = 3, le.angleThreshold = Math.PI / 4, le.scrollToOverflow = ScrollAbstract.IGNORE_SCROLL_TO_OVERFLOW, le.paging = !0, le.repeatPages = !0, le.repeatedPagesCount = $sections.length, le.scrollToAcceleration = 2, le.scrollToDeceleration = .2, le.pageSnapPageChangeMinSpeed = .1, le.releaseMode = ScrollAbstract.PAGE_SNAP_RELEASE_MODE, le.addEventListener("update", function(e) {
            v(e.position)
        }), Be = $sections.eq(0), le.addEventListener("scrollToComplete", u), $window.on("touchstart", s), $window.on("touchmove", s), $window.on("touchend", s)
    }, Engine.launch = function() {
        Ue = 1, v(0, !0), $sections.addClass("hidden"), $sections.data("hidden", !0), b($sections, 1), requestAnimationFrame(t)
    };
    var Ve, We = {
            ratio: 0
        },
        Ge = "",
        ze = "",
        qe = "";
    Engine.resize = function() {
        function t() {
            isNaN(n) || le.setTo(j * n)
        }
        if (B = $sectionsContainer.height(), j) var n = le.currentPageIndex % $sections.length;
        switch (j = B - Ae * be, $sections.css({
            height: j
        }), le.updateDimensions(j, j * $sections.length), le.changePagesSize(j), Ue) {
            case 1:
                d();
                break;
            case Te:
                t();
                break;
            case ve:
                t(), (o = K.find(".cover")).height(j), TweenMax.killTweensOf(ie), k(ie, -j);
                a = parseFloat($sectionsContainer.css("bottom")) + Ae * be;
                re.each(function(t) {
                    var n = e(this);
                    TweenMax.killTweensOf(n), k(n, a + t * be)
                }), TweenMax.killTweensOf(K), K.css({
                    transform: U(-j),
                    height: j + viewportHeight + 1
                }), x();
                break;
            case Se:
                var o = K.find(".cover");
                o.height(j), k(ie, -j);
                var a = parseFloat($sectionsContainer.css("bottom")) + Ae * be;
                re.each(function(t) {
                    k(e(this), a + t * be)
                }), K.css({
                    transform: U(-j),
                    height: j + viewportHeight + 1
                }), ce.updateDimensions(viewportHeight, K.find(".content").innerHeight());
                var i = ce.currentPosition;
                i < 0 && (i = 0), ce.setTo(i), ce.accommodateNow();
                break;
            case Ee:
                TweenMax.killTweensOf(K), k(K, 0), re.each(function(t) {
                    var n = e(this);
                    TweenMax.killTweensOf(n), k(n, (t + 1) * be)
                }), t(), F()
        }
    }, Engine.nextPage = function() {
        l()
    };
    var Be, je, Ye, Xe, Qe, Ke = !1,
        Je = !1,
        Ze = null,
        et = !1,
        tt = 0,
        nt = !1,
        ot = 0;
    Engine.openSection = function(e) {
        DeepLinks.navigateToHash("/" + e.data("sectionName"))
    }, Engine.closeSectionFront = L, Engine.revealFooter = V, Engine.coverFooter = W
}(jQuery),
function(e) {
    function t() {
        function t() {
            o || a || i || u || n()
        }
        c = (new Date).getTime(), (d = new Spinner).$element.css({
            position: "absolute",
            left: "50%",
            top: "50%"
        }), $wrapper.prepend(d.$element), e("[data-preload]").each(function() {
            var t = e(this);
            "IMG" == this.tagName && t.is("[src]") && r.push(this.src)
        });
        for (var o = r.length, a = s.length, i = l.length, u = 0, g = 0; g < r.length; g++) {
            var f = r[g],
                m = e("<img>");
            m.on("load error", function() {
                o--, t()
            }), m[0].src = f
        }
        for (g = 0; g < s.length; g++) {
            f = s[g];
            e.ajax({
                url: f,
                complete: function() {
                    a--, t()
                }
            })
        }
        for (g = 0; g < l.length; g++)(0, l[g])(function() {
            i--, t()
        });
        for (var h in PAGES) {
            var p = PAGES[h];
            p.preload && (u++, p.preload(function() {
                u--, t()
            }))
        }
        t()
    }

    function n() {
        var e = (new Date).getTime(),
            t = c + i - e;
        t <= 0 ? o() : setTimeout(o, t)
    }

    function o() {
        for (var e in PAGES) {
            var t = PAGES[e];
            t && t.init && t.init()
        }
        $window.trigger("preloaded"), d.stop(), a(), requestAnimationFrame(function() {
            $sectionsContainer.removeClass("hidden"), Engine.launch()
        })
    }

    function a() {
        e("[data-preload][data-src]").each(function() {
            var t = e(this),
                n = t.attr("data-src");
            t.on("load", function() {
                t.addClass("loaded")
            }), this.src = n
        })
    }
    var i = 0,
        r = [],
        s = ["/styles/type/maisonneuebook-webfont.woff", "/styles/type/maisonneuebold-webfont.woff"],
        l = [];
    e(function() {
        l.push(Moons.getVertexShaderText), l.push(Moons.getFragmentShaderText)
    });
    var c, d;
    e(t)
}(jQuery);
var PAGES = [];
! function(e) {
    function t() {
        Engine.init(), $sectionsFader = e('<div id="sections-fader"/>'), $sectionsCropper.prepend($sectionsFader), $sectionsFader.on("tapone", o), $sections.find(".content-wrapper").cleanWhitespace(), $sections.find(".images-mosaic").cleanWhitespace(), $footer.find(".button").on("tapone", a), $window.resize(i), i(), e(".view-more-btn").on("tapone", function(t) {
            Engine.openSection(e(this).parents("section")), ga("send", "pageview", e(t.currentTarget).attr("data-section"))
        }), e(".next-section-button").on("tapone", function() {
            Engine.nextPage()
        })
    }

    function n() {
        r = !0, Engine.revealFooter(), $footer.addClass("opened")
    }

    function o() {
        r = !1, Engine.coverFooter(), $footer.removeClass("opened")
    }

    function a() {
        r ? o() : n()
    }

    function i() {
        $body.css("height", viewportHeight), e(".breadcrumb.vertical").each(function(t) {
            $window.width() < 680 ? e(this).css("top", viewportHeight / 2 - e(this).width() / 2) : e(this).css("top", viewportHeight / 2 + e(this).width() / 2)
        }), Engine.resize()
    }
    e(t);
    var r = !1
}(jQuery);
var Moons;
! function(e) {
    function t(n) {
        e.ajax({
            url: /Mac OS X 10_1[2-9]/.test(navigator.userAgent) ? "/js/glsl/moons/vertex-sierra.glsl.txt" : "/js/glsl/moons/vertex.glsl.txt",
            cache: !0,
            success: function(e) {
                o = e, n()
            },
            error: function() {
                setTimeout(t, 100)
            }
        })
    }

    function n(t) {
        e.ajax({
            url: "/js/glsl/moons/fragment.glsl.txt",
            cache: !0,
            success: function(e) {
                a = e, t()
            },
            error: function() {
                setTimeout(n, 100)
            }
        })
    }
    var o, a, i = -1 != navigator.userAgent.indexOf("Chrome"),
        r = -1 != navigator.userAgent.indexOf("CriOS"),
        s = i || r,
        l = (navigator.userAgent.indexOf("Safari"), navigator.userAgent.toLowerCase().indexOf("firefox"), 2),
        c = "vec3(" + 24 / 255 + ", " + 27 / 255 + ", " + 34 / 255 + ")",
        d = 3,
        u = 400,
        g = 23,
        f = .7,
        m = !0,
        h = 2,
        p = !1,
        T = 10,
        v = 7,
        S = 8,
        E = .8,
        w = 0,
        R = 18,
        A = .5,
        b = 2,
        C = 50,
        _ = .2,
        O = 1,
        x = 3,
        M = 1,
        P = 2,
        y = .5,
        D = 0,
        I = 50,
        L = .2,
        $ = 1,
        H = 2,
        N = .5,
        F = 1.5,
        k = .9,
        U = 3,
        V = 1.3,
        W = 0,
        G = 0,
        z = .15,
        q = 1,
        B = .15,
        j = 1,
        Y = .1,
        X = 1,
        Q = -.15,
        K = [],
        J = function(e, t) {
            this.$moonContainer = e, this.angleStartRatio = t <= .5 ? 0 : 2 * (t - .5), this.angleStartRatio -= B / 4, this.angleEndRatio = t >= .5 ? 1 : 2 * t, this.angleEndRatio += z / 4
        };
    (Moons = function(t, n) {
        function i() {
            oe = n.width(), ae = n.height(), ie = Math.round(ae * (1 + W)), se = ie / ae - 1, re = pixelRatio <= 1 ? l * pixelRatio : pixelRatio
        }

        function r() {
            var e = oe * re,
                t = ie * re;
            He.attr("width", e), He.attr("height", t), He.css({
                width: oe,
                height: ie,
                marginTop: ae - ie
            }), xe.uniform1f(le, se), xe.uniform2f(ce, e, t), xe.uniform1f(ge, h * re), xe.viewport(0, 0, e, t)
        }

        function s() {
            for (var e = He.offset(), t = e.top + ae, n = 0; n < K.length; n++) {
                var o = K[n],
                    a = o.$moonContainer.offset(),
                    i = o.$moonContainer.width(),
                    r = o.$moonContainer.height();
                o.left = (a.left - e.left) / oe * 2 - 1, o.bottom = (t - (a.top + r)) / ae * 2 - 1, o.widthRatio = i / oe / 2, o.heightRatio = r / ae / 2, o.logicalWidth = i, o.logicalHeight = r
            }
            xe.uniform2f(de, i * re, r * re)
        }

        function Z(e) {
            return "number" == typeof e && isFinite(e) && Math.floor(e) === e ? e + ".0" : e.toString()
        }

        function ee() {
            xe = He[0].getContext("webgl") || He[0].getContext("experimental-webgl")
        }

        function te() {
            function e() {
                for (var e = 0; e < K.length; e++) {
                    var t, n = K[e],
                        o = [];
                    (t = Math.round(n.logicalWidth / d)) > u && (t = u);
                    for (var a = 2 / t, i = 2 / g, r = g - 1; r >= 0; r--)
                        for (var s = i * r - 1, l = s + i, c = 0; c < t; c++) {
                            var f = a * c - 1,
                                m = f + a;
                            o.push(f, s), o.push(m, s), o.push(f, l), o.push(f, l), o.push(m, s), o.push(m, l)
                        }
                    n.columns = t, n.points = o
                }
            }

            function t() {
                n()
            }

            function n() {
                xe.uniform1f(Be, Qe + (new Date).getTime() - Xe);
                for (var e = 0; e < K.length; e++) {
                    var t = K[e];
                    xe.uniform1f(fe, t.left), xe.uniform1f(me, t.bottom), xe.uniform1f(he, t.widthRatio), xe.uniform1f(pe, t.heightRatio), xe.uniform1f(Te, t.angleStartRatio), xe.uniform1f(ve, t.angleEndRatio), xe.uniform1fv(Se, t.frequenciesValues), xe.uniform1fv(Ee, t.frequenciesSpeed), xe.uniform1fv(we, t.frequenciesMaskFreq), xe.uniform1fv(Re, t.frequenciesMaskSpeed), xe.uniform1fv(Ae, t.frequenciesMaskAmplitude), xe.uniform1fv(be, t.frequenciesSecondaryMaskFreq), xe.uniform1fv(Ce, t.frequenciesSecondaryMaskSpeed), xe.uniform1fv(_e, t.frequenciesSecondaryMaskAmplitude), xe.uniform1fv(Oe, t.frequenciesMaskChop);
                    var n = xe.createBuffer();
                    xe.bindBuffer(xe.ARRAY_BUFFER, n), xe.bufferData(xe.ARRAY_BUFFER, new Float32Array(t.points), xe.STATIC_DRAW), xe.enableVertexAttribArray(ue), xe.vertexAttribPointer(ue, 2, xe.FLOAT, !1, 0, 0), xe.drawArrays(xe.TRIANGLES, 0, 6 * t.columns * g)
                }
            }
            Ne.$canvas = He, Me = He[0], Ne.canvas = Me, $e = $e.replace("%BG_COLOR%", c), Le = Le.replace("%LINE_COUNT%", g), $e = $e.replace("%LINE_COUNT%", g), $e = $e.replace("%LINE_OPACITY%", f), Le = Le.replace("%FIX_LINE_THICKNESS%", m), $e = $e.replace("%FIX_LINE_THICKNESS%", m), Le = Le.replace("%SNAP_TO_PIXEL%", p), Le = Le.replace("%WAVES%", T), Le = Le.replace("%FREQUENCIES_PER_WAVE%", v), Le = Le.split("%TOTAL_FREQUENCIES%").join(T * v), Le = Le.replace("%MAX_HEIGHT%", Z(U)), Le = Le.replace("%STEEPNESS%", Z(V)), $e = $e.replace("%FADE_RATIO%", Z(G)), Le = Le.replace("%RELIEF_RIGHT_FADE_RATIO%", Z(z)), Le = Le.replace("%RELIEF_RIGHT_FADE_EASE%", Z(q)), Le = Le.replace("%RELIEF_LEFT_FADE_RATIO%", Z(B)), Le = Le.replace("%RELIEF_LEFT_FADE_EASE%", Z(j)), Le = Le.replace("%RELIEF_VERTICAL_FADE_RATIO%", Z(Y)), Le = Le.replace("%WIDTH_DURATION%", Z(X)), Le = Le.replace("%SPEED%", Z(Q)), Pe = compileShader(xe, Le, xe.VERTEX_SHADER), ye = compileShader(xe, $e, xe.FRAGMENT_SHADER), De = createProgram(xe, Pe, ye), xe.useProgram(De), ue = xe.getAttribLocation(De, "position"), ge = xe.getUniformLocation(De, "LINE_THICKNESS"), fe = xe.getUniformLocation(De, "left"), me = xe.getUniformLocation(De, "bottom"), he = xe.getUniformLocation(De, "widthRatio"), pe = xe.getUniformLocation(De, "heightRatio"), Te = xe.getUniformLocation(De, "angleStartRatio"), ve = xe.getUniformLocation(De, "angleEndRatio"), Se = xe.getUniformLocation(De, "frequenciesValues"), Ee = xe.getUniformLocation(De, "frequenciesSpeed"), we = xe.getUniformLocation(De, "frequenciesMaskFreq"), Re = xe.getUniformLocation(De, "frequenciesMaskSpeed"), Ae = xe.getUniformLocation(De, "frequenciesMaskAmplitude"), be = xe.getUniformLocation(De, "frequenciesSecondaryMaskFreq"), Ce = xe.getUniformLocation(De, "frequenciesSecondaryMaskSpeed"), _e = xe.getUniformLocation(De, "frequenciesSecondaryMaskAmplitude"), Oe = xe.getUniformLocation(De, "frequenciesMaskChop");
            for (var o = 0; o < K.length; o++) {
                for (var a = K[o], l = [], h = [], W = [], J = [], ee = [], te = [], ne = [], oe = [], ae = [], ie = 0; ie < T; ie++)
                    for (var re = 0; re < v; re++) {
                        var se = S * Math.pow(E, w + (R - w) * Math.random()),
                            Fe = A + (b - A) * Math.random(),
                            ke = C * Math.pow(_, O + (x - O) * Math.random()),
                            Ue = M + (P - M) * Math.random(),
                            Ve = y + (1 - y) * Math.random(),
                            We = I * Math.pow(L, $ + (H - $) * Math.random()),
                            Ge = N + (F - N) * Math.random(),
                            ze = k + (1 - k) * Math.random(),
                            qe = Math.random() * D;
                        l.push(se), h.push(Fe), W.push(ke), J.push(Ue), ee.push(Ve), te.push(We), ne.push(Ge), oe.push(ze), ae.push(qe)
                    }
                a.frequenciesValues = l, a.frequenciesSpeed = h, a.frequenciesMaskFreq = W, a.frequenciesMaskSpeed = J, a.frequenciesMaskAmplitude = ee, a.frequenciesSecondaryMaskFreq = te, a.frequenciesSecondaryMaskSpeed = ne, a.frequenciesSecondaryMaskAmplitude = oe, a.frequenciesMaskChop = ae
            }
            var Be = xe.getUniformLocation(De, "TIME");
            le = xe.getUniformLocation(De, "additionalCanvas"), ce = xe.getUniformLocation(De, "resolution"), de = xe.getUniformLocation(De, "moonResolution"), i(), r(), s(), e(), Ne.resize = function() {
                i(), r(), s(), e()
            };
            var je, Ye = !1,
                Xe = (new Date).getTime(),
                Qe = -8e5 - 2e5 * Math.random();
            Ne.draw = function() {
                var e = Ye;
                Ne.start(), n(), e || Ne.pause()
            }, Ne.start = function() {
                if (!Ye) {
                    if (Ye = !0, je) {
                        var e = (new Date).getTime() - je;
                        Xe += e
                    }
                    Ie = setInterval(t, 40)
                }
            }, Ne.pause = function() {
                Ye && (Ye = !1, je = (new Date).getTime(), clearTimeout(Ie))
            }, Ne.success = !0
        }

        function ne() {
            Me = null, Le = null, $e = null, Pe = null, ye = null, De = null, Ie && (clearTimeout(Ie), Ie = null), Ne.resize = null, Ne.start = null, Ne.pause = null
        }
        this.success = !1, t.each(function(n) {
            var o = e(this),
                a = new J(o, n / t.length);
            K.push(a)
        });
        var oe, ae, ie, re, se, le, ce, de, ue, ge, fe, me, he, pe, Te, ve, Se, Ee, we, Re, Ae, be, Ce, _e, Oe, xe, Me, Pe, ye, De, Ie, Le = o,
            $e = a,
            He = e("<canvas></canvas>"),
            Ne = this;
        try {
            ee();
            try {
                te()
            } catch (e) {
                ne(), console.log("Error while doing webgl stuff")
            }
        } catch (e) {
            console.log("Could not obtain webgl object")
        }
        this.success || (ne(), He = null, Ne = null)
    }).getVertexShaderText = t, Moons.getFragmentShaderText = n
}(jQuery),
function(e) {
    function t(t) {
        l = e('<img class="fallback">'), c = l[0], DEVICE_TYPE == DEVICE_TYPE_PHONE ? c.src = "styles/img/works/voguearabia/bg-mobile.jpg" : c.src = "styles/img/works/voguearabia/bg.jpg", l.on("load", t)
    }

    function n() {}
    var o, a, i, r, s, l, c, d = !1,
        u = {};
    PAGES["work-voguearabia"] = u, u.preload = function(n) {
        o = e(".section-work-voguearabia"), r = o.find(".background"), DEVICE_TYPE != DEVICE_TYPE_DESKTOP || IS_SAFARI_7 ? (d = !0, t(n)) : Triangles.getShadersText(function() {
            (i = new Triangles(r)).smoothingStrength = 2, i.webglSmoothingStyle = Triangles.WEBGL_SMOOTHING_STYLE_LINEAR, i.mode = e.extend({}, Triangles.PRESETS["mouse-circle-wavy"], {
                name: "voguearabia",
                sources: ["styles/img/works/voguearabia/bg.jpg", "styles/img/works/voguearabia/bg-mask.png"],
                bitmapArea: !0,
                bitmapAreaSource: 1,
                verticalAlign: 0,
                gridPanY: !0,
                gridPanYCycleDuration: 36e3
            }), i.loadAssets(function() {
                i.init(), i.success ? n() : (d = !0, t(n))
            })
        })
    }, u.init = function() {
        if (d ? r.append('<div class="fallback" style="background-image: url(\'' + c.src + "');\"></div>") : ((w = o.find(".view-more-btn")).on("mouseenter", function() {
                TweenMax.to(i.mode, .4, {
                    mouseCircleRadius: 2.1,
                    ease: Power2.easeOut,
                    onUpdate: i.updateMouseCircleRadius
                })
            }), w.on("mouseleave", function() {
                TweenMax.to(i.mode, .4, {
                    mouseCircleRadius: 1.3,
                    ease: Power2.easeOut,
                    onUpdate: i.updateMouseCircleRadius
                })
            }), o.find(".content-wrapper .image").remove(), r.append(i.canvas), s = i.$canvas, o.on("showing", function() {
                i.start()
            }), o.on("entered", function() {
                i.start()
            }), o.on("hiding", function() {
                i.pause()
            }), o.on("hidden", function() {
                i.pause()
            }), o.on("opened", function() {
                i.pause()
            }), o.on("closing", function() {
                i.start()
            }), i.draw(), $window.on("resize", i.resize)), a = o.find(".detail-page"), FOLLOW_ENABLED) {
            var t = a.find(".content-wrapper.title"),
                l = t.find("h1"),
                u = t.find("ul.credits li"),
                g = a.find(".block.block-1").find("img"),
                f = a.find(".block.block-2").find(".images-mosaic img"),
                m = a.find(".block.block-3"),
                h = m.find(".bg.top"),
                p = m.find(".bg.bottom"),
                T = m.find(".description"),
                v = m.find("img"),
                S = a.find(".block.block-4"),
                E = e();
            E = (E = (E = (E = E.add(S.find("h3").first())).add(S.find(".awards li"))).add(S.find("h3").last())).add(S.find(".tweets li"));
            var w = S.find(".launch-website-btn"),
                R = [].concat(l.get(), u.get(), g.get(), f.get(), h.get(), T.get(), v.get(), p.get(), E.get(), w.get()),
                A = e(R);
            Follow.setContiguousTargets(A), f.each(function(t) {
                var n = e(this),
                    o = t - 2;
                o < 0 ? n.data("follow-target-up", g.last()) : n.data("follow-target-up", f.eq(o)), (o = t + 2) > f.length - 1 ? n.data("follow-target-down", h) : n.data("follow-target-down", f.eq(o))
            }), A.attr("follow-easing", .4), E.attr("follow-easing", .6), w.attr("follow-easing", .6), A.attr("data-follow-direction-change-mode", Follow.DIRECTION_CHANGE_MODE_PUSH), follow = new Follow("offset", FOLLOW_EFFECT_MODE), follow.ignoreTargetsBelowTop = -1200, follow.ignoreTargetsAboveTop = 1200, follow.add(A), o.on("opening-animation", follow.enable), o.on("closing", follow.disable)
        }
        $window.resize(n), $window.on("preloaded", n)
    }
}(jQuery),
function(e) {
    function t(t) {
        function n() {
            for (var n = 1; n < o.length; n++) {
                var a = e("<img>");
                a[0].src = o[n], d = d.add(a)
            }
            t()
        }
        var o = ["styles/img/works/flatguitars/flatguitars-landing-1.png", "styles/img/works/flatguitars/flatguitars-landing-2.png", "styles/img/works/flatguitars/flatguitars-landing-3.png"],
            a = e("<img>");
        a.on("load", n), a[0].src = o[0], d = d.add(a)
    }

    function n() {
        var e = i.width(),
            t = Math.round(e - (c.offset().left - i.offset().left));
        r.css("width", t), l.mode.flatGuitarsBgStartLeft = (t - e / 2) / t * 2 - 1, l.mode.guitarTop = 1 - (c.offset().top - i.offset().top) / i.height() * 2, l.mode.guitarWidth = c.width() / t * 2, l.mode.guitarHeight = c.height() / i.height() * 2
    }

    function o() {
        var e = $window.width() < 680 ? 1150 : 1e3,
            t = $window.height() / e,
            o = 606 * t;
        c.css({
            width: o,
            height: 856 * t,
            marginLeft: -o / 2,
            marginTop: -70 * t
        }), u || (n(), l.updateFlatGuitarsDimensions(), l.resize())
    }
    var a, i, r, s, l, c, d = e(),
        u = !1,
        g = {};
    PAGES["work-flatguitars"] = g;
    var f;
    g.preload = function(o) {
        a = e(".section-work-flatguitars"), i = a.find(".internal-cropper > .cover"), r = a.find(".background"), c = a.find(".image"), DEVICE_TYPE != DEVICE_TYPE_DESKTOP || IS_SAFARI_7 ? (u = !0, t(o)) : Triangles.getShadersText(function() {
            (l = new Triangles(r)).smoothingStrength = 2, l.webglSmoothingStyle = Triangles.WEBGL_SMOOTHING_STYLE_FULL, l.mode = e.extend({}, Triangles.PRESETS["mouse-circle-wavy"], {
                name: "flat-guitars",
                sources: ["styles/img/triangles/flatguitars_pattern_background.png", "styles/img/works/flatguitars/flatguitars-landing-1.png", "styles/img/works/flatguitars/flatguitars-landing-2.png", "styles/img/works/flatguitars/flatguitars-landing-3.png"],
                activeSource: 1,
                isFlatGuitars: !0,
                flatGuitarsBgPatternSource: 0,
                mouseCircleRadius: 1.3
            }), n(), l.loadAssets(function() {
                l.init(), l.success ? o() : (u = !0, t(o))
            })
        })
    }, g.init = function() {
        if (u ? (r.remove(), c.append(d), a.on("cycleChange", function(e, t) {
                var n = t.newCycle % d.length;
                n < 0 && (n += d.length), d.css("display", "none"), d.eq(n).css("display", "")
            })) : (o(), l.success && ((v = a.find(".view-more-btn")).on("mouseenter", function() {
                TweenMax.to(l.mode, .4, {
                    mouseCircleRadius: 2.1,
                    ease: Power2.easeOut,
                    onUpdate: l.updateMouseCircleRadius
                })
            }), v.on("mouseleave", function() {
                TweenMax.to(l.mode, .4, {
                    mouseCircleRadius: 1.3,
                    ease: Power2.easeOut,
                    onUpdate: l.updateMouseCircleRadius
                })
            }), r.append(l.canvas), $canvas = l.$canvas, a.on("showing", function() {
                l.start()
            }), a.on("entered", function() {
                l.start()
            }), a.on("hiding", function() {
                l.pause()
            }), a.on("hidden", function() {
                l.pause()
            }), a.on("opened", function() {
                l.pause()
            }), a.on("closing", function() {
                l.start()
            }), l.draw(), a.on("cycleChange", function(e, t) {
                var n = t.newCycle % (l.mode.sources.length - 1);
                n < 0 && (n += l.mode.sources.length - 1), l.mode.activeSource = n + 1, l.updateTexture(), l.draw()
            }))), s = a.find(".detail-page"), FOLLOW_ENABLED) {
            var t = s.find(".content-wrapper.title"),
                n = t.find("ul.credits li"),
                i = s.find(".images-mosaic"),
                g = s.find(".content-column.type-footer"),
                m = e();
            m = m.add(t.find("h1")), m = m.add(n), m = m.add(s.find(".block-1 .image-single")), m = e(m.get().concat(s.find(".block-2 .bg.top").get().concat(s.find(".block-2 .image-single").get()).concat(s.find(".block-2 .bg.bottom").get())));
            var h = i.find("img"),
                p = s.find(".block.inverted-bg-color > .bg"),
                T = e();
            T = (T = (T = (T = T.add(g.find("h3").first())).add(g.find(".awards li"))).add(g.find("h3").last())).add(g.find(".tweets li"));
            var v = g.find(".launch-website-btn");
            Follow.setContiguousTargets(m), m.last().data("follow-target-down", h.first()), h.each(function(t) {
                var n = e(this),
                    o = t - 3;
                o < 0 ? n.data("follow-target-up", m.last()) : n.data("follow-target-up", h.eq(o)), (o = t + 3) > h.length - 1 ? n.data("follow-target-down", p) : n.data("follow-target-down", h.eq(o))
            }), p.data("follow-target-up", h.last()), p.data("follow-target-down", T.first()), T.first().data("follow-target-up", p), Follow.setContiguousTargets(T), T.last().data("follow-target-down", v), v.data("follow-target-up", T.last());
            var S = e();
            (S = (S = (S = (S = (S = S.add(m)).add(h)).add(p)).add(T)).add(v)).attr("follow-easing", .4), T.attr("follow-easing", .6), v.attr("follow-easing", .6), S.attr("data-follow-direction-change-mode", Follow.DIRECTION_CHANGE_MODE_PUSH), (f = new Follow("offset", FOLLOW_EFFECT_MODE)).ignoreTargetsBelowTop = -1200, f.ignoreTargetsAboveTop = 1200, f.add(S), a.on("opening-animation", f.enable), a.on("closing", f.disable)
        }
        $window.resize(o), $window.on("preloaded", o)
    }
}(jQuery),
function(e) {
    function t(t) {
        s = e('<img class="fallback">'), l = s[0], DEVICE_TYPE == DEVICE_TYPE_PHONE ? l.src = "styles/img/works/rosebud/rosebud-fallback-mobile.jpg" : l.src = "styles/img/works/rosebud/rosebud.jpg", s.on("load", t)
    }

    function n() {}
    var o, a, i, r, s, l, c = !1,
        d = {};
    PAGES["work-rosebud"] = d, d.preload = function(n) {
        o = e(".section-work-rosebud"), r = o.find(".background"), DEVICE_TYPE != DEVICE_TYPE_DESKTOP || IS_SAFARI_7 ? (c = !0, t(n)) : Triangles.getShadersText(function() {
            (i = new Triangles(r)).smoothingStrength = 2, i.webglSmoothingStyle = Triangles.WEBGL_SMOOTHING_STYLE_LINEAR, i.mode = e.extend({}, Triangles.PRESETS["mouse-circle-wavy"], {
                sources: ["styles/img/works/rosebud/rosebud.jpg"],
                verticalAlign: -.2
            }), i.loadAssets(function() {
                i.init(), i.success ? n() : (c = !0, t(n))
            })
        })
    }, d.init = function() {
        if (c ? r.append('<div class="fallback" style="background-image: url(\'' + l.src + "');\"></div>") : ((O = o.find(".view-more-btn")).on("mouseenter", function() {
                TweenMax.to(i.mode, .4, {
                    mouseCircleRadius: 2.1,
                    ease: Power2.easeOut,
                    onUpdate: i.updateMouseCircleRadius
                })
            }), O.on("mouseleave", function() {
                TweenMax.to(i.mode, .4, {
                    mouseCircleRadius: 1.3,
                    ease: Power2.easeOut,
                    onUpdate: i.updateMouseCircleRadius
                })
            }), r.append(i.canvas), o.on("showing", function() {
                i.start()
            }), o.on("entered", function() {
                i.start()
            }), o.on("hiding", function() {
                i.pause()
            }), o.on("hidden", function() {
                i.pause()
            }), o.on("opened", function() {
                i.pause()
            }), o.on("closing", function() {
                i.start()
            }), i.draw(), $window.on("resize", i.resize)), a = o.find(".detail-page"), FOLLOW_ENABLED) {
            var t = a.find(".content-wrapper.title"),
                s = t.find("h1"),
                d = t.find("ul.credits li"),
                u = a.find(".block.block-1").find("img"),
                g = a.find(".block.block-2"),
                f = g.find(".description"),
                m = g.find(".images-mosaic img"),
                h = a.find(".block.block-3"),
                p = h.find(".bg.top"),
                T = h.find(".bg.bottom"),
                v = h.find(".description"),
                S = h.find("img"),
                E = a.find(".block.block-5"),
                w = E.find(".bg.top"),
                R = E.find(".bg.bottom"),
                A = E.find(".description"),
                b = E.find(".images-mosaic img"),
                C = a.find(".block-6"),
                _ = e();
            _ = (_ = (_ = (_ = _.add(C.find("h3").first())).add(C.find(".awards li"))).add(C.find("h3").last())).add(C.find(".tweets li"));
            var O = C.find(".launch-website-btn"),
                x = [].concat(s.get(), d.get(), u.get(), f.get(), m.get(), p.get(), v.get(), S.get(), T.get(), w.get(), A.get(), b.get(), R.get(), _.get(), O.get()),
                M = e(x);
            Follow.setContiguousTargets(M), m.each(function(t) {
                var n = e(this),
                    o = t - 2;
                o < 0 ? n.data("follow-target-up", f) : n.data("follow-target-up", m.eq(o)), (o = t + 2) > m.length - 1 ? n.data("follow-target-down", p) : n.data("follow-target-down", m.eq(o))
            }), b.each(function(t) {
                var n = e(this),
                    o = t - 2;
                o < 0 ? n.data("follow-target-up", A) : n.data("follow-target-up", b.eq(o)), (o = t + 2) > b.length - 1 ? n.data("follow-target-down", R) : n.data("follow-target-down", b.eq(o))
            }), M.attr("follow-easing", .4), T.attr("follow-easing", 1), w.attr("follow-easing", 1), _.attr("follow-easing", .6), O.attr("follow-easing", .6), M.attr("data-follow-direction-change-mode", Follow.DIRECTION_CHANGE_MODE_PUSH), follow = new Follow("offset", FOLLOW_EFFECT_MODE), follow.ignoreTargetsBelowTop = -1200, follow.ignoreTargetsAboveTop = 1200, follow.add(M), o.on("opening-animation", follow.enable), o.on("closing", follow.disable)
        }
        $window.on("preloaded", function() {
            $window.resize(n)
        })
    }
}(jQuery),
function(e) {
    function t() {
        r.mode.monkeyTop = 2 * (1 - (s.offset().top - a.offset().top) / a.height()) - 1
    }

    function n() {}
    var o, a, i, r, s, l, c, d = !1,
        u = {};
    PAGES["work-satorisan"] = u, u.preload = function(n) {
        o = e(".section-work-satorisan"), a = o.find(".internal-cropper > .cover"), s = o.find("#monkey-reference"), l = o.find(".background"), DEVICE_TYPE != DEVICE_TYPE_DESKTOP || IS_SAFARI_7 ? (d = !0, n()) : Triangles.getShadersText(function() {
            (r = new Triangles(l)).smoothingStrength = 2, r.webglSmoothingStyle = Triangles.WEBGL_SMOOTHING_STYLE_LINEAR, r.mode = e.extend({}, Triangles.PRESETS["mouse-circle-wavy"], {
                resamplingTechnique: Triangles.NEAREST,
                sources: ["styles/img/works/satorisan/bg.jpg", "styles/img/works/satorisan/webgl-sprite.png"],
                monkeySource: 1,
                gridSize: .1,
                isMonkey: !0
            }), t(), r.loadAssets(function() {
                r.init(), r.success || (d = !0), n()
            })
        })
    }, u.init = function() {
        if (d) {
            var a = e('\t\t\t\t<div id="monkey" >\t\t\t\t\t<div id="monkey-body">\t\t\t\t\t\t<div id="monkey-hand-left"></div>\t\t\t\t\t\t<div id="monkey-hand-left-shadow"></div>\t\t\t\t\t\t<div id="monkey-hand-left-grow"></div>\t\t\t\t\t\t<div id="monkey-hand-right-grow"></div>\t\t\t\t\t\t<div id="monkey-hand-right"></div>\t\t\t\t\t\t<div id="monkey-hand-right-shadow"></div>\t\t\t\t\t\t<div id="monkey-head" class="change"></div>\t\t\t\t\t\t<div id="monkey-body-bottom"></div>\t\t\t\t\t\t<div id="monkey-light"></div>\t\t\t\t\t</div>\t\t\t\t</div>\t\t\t');
            s.before(a), setInterval(function() {
                o.find("#monkey-head").toggleClass("change")
            }, 1e3), console.log(l)
        } else(x = o.find(".view-more-btn")).on("mouseenter", function() {
            TweenMax.to(r.mode, .4, {
                mouseCircleRadius: 2.1,
                ease: Power2.easeOut,
                onUpdate: r.updateMouseCircleRadius
            })
        }), x.on("mouseleave", function() {
            TweenMax.to(r.mode, .4, {
                mouseCircleRadius: 1.3,
                ease: Power2.easeOut,
                onUpdate: r.updateMouseCircleRadius
            })
        }), l.append(r.canvas), c = r.$canvas, o.on("showing", function() {
            r.start()
        }), o.on("entered", function() {
            r.start()
        }), o.on("hiding", function() {
            r.pause()
        }), o.on("hidden", function() {
            r.pause()
        }), o.on("opened", function() {
            r.pause()
        }), o.on("closing", function() {
            r.start()
        }), r.draw(), $window.on("resize", function() {
            t(), r.updateMonkeyTop(), r.resize()
        }), o.find("#monkey").remove();
        if (i = o.find(".detail-page"), FOLLOW_ENABLED) {
            var u = i.find(".content-wrapper.title"),
                g = u.find("h1"),
                f = u.find("ul.credits li"),
                m = i.find(".block.block-1").find("img"),
                h = i.find(".block.block-2"),
                p = h.find(".bg.top"),
                T = h.find(".bg.bottom"),
                v = h.find(".description"),
                S = h.find("img"),
                E = i.find(".block.block-3").find("img"),
                w = i.find(".block.block-4"),
                R = w.find(".bg.top"),
                A = w.find(".bg.bottom"),
                b = w.find(".description"),
                C = w.find(".images-mosaic img"),
                _ = i.find(".content-column.type-footer"),
                O = e();
            O = (O = (O = (O = O.add(_.find("h3").first())).add(_.find(".awards li"))).add(_.find("h3").last())).add(_.find(".tweets li"));
            var x = _.find(".launch-website-btn"),
                M = [].concat(g.get(), f.get(), m.get(), p.get(), v.get(), S.get(), T.get(), E.get(), R.get(), b.get(), C.get(), A.get(), O.get(), x.get()),
                P = e(M);
            Follow.setContiguousTargets(P), C.each(function(t) {
                var n = e(this),
                    o = t - 2;
                o < 0 ? n.data("follow-target-up", b) : n.data("follow-target-up", C.eq(o)), (o = t + 2) > C.length - 1 ? n.data("follow-target-down", A) : n.data("follow-target-down", C.eq(o))
            }), P.attr("follow-easing", .4), O.attr("follow-easing", .6), x.attr("follow-easing", .6), P.attr("data-follow-direction-change-mode", Follow.DIRECTION_CHANGE_MODE_PUSH), follow = new Follow("offset", FOLLOW_EFFECT_MODE), follow.ignoreTargetsBelowTop = -1200, follow.ignoreTargetsAboveTop = 1200, follow.add(P), o.on("opening-animation", follow.enable), o.on("closing", follow.disable)
        }
        $window.resize(n), $window.on("preloaded", n)
    }
}(jQuery),
function(e) {
    function t(t) {
        l = e('<img class="fallback">'), c = l[0], DEVICE_TYPE == DEVICE_TYPE_PHONE ? c.src = "styles/img/works/jwt/bg-mobile.jpg" : c.src = "styles/img/works/jwt/bg.jpg", l.on("load", t)
    }

    function n() {}
    var o, a, i, r, s, l, c, d = !1,
        u = {};
    PAGES["work-jwt"] = u, u.preload = function(n) {
        o = e(".section-work-jwt"), r = o.find(".background"), DEVICE_TYPE != DEVICE_TYPE_DESKTOP || IS_SAFARI_7 ? (d = !0, t(n)) : Triangles.getShadersText(function() {
            (i = new Triangles(r)).smoothingStrength = 2, i.webglSmoothingStyle = Triangles.WEBGL_SMOOTHING_STYLE_LINEAR, i.mode = e.extend({}, Triangles.PRESETS["mouse-circle-wavy"], {
                name: "jwt",
                sources: ["styles/img/works/jwt/bg.jpg", "styles/img/works/jwt/ovni-webgl.gif"],
                verticalAlign: 0,
                isJWT: !0,
                jwtSource: 1
            }), i.loadAssets(function() {
                i.init(), i.success ? n() : (d = !0, t(n))
            })
        })
    }, u.init = function() {
        if (d ? r.append('<div class="fallback" style="background-image: url(\'' + c.src + "');\"></div>") : ((w = o.find(".view-more-btn")).on("mouseenter", function() {
                TweenMax.to(i.mode, .4, {
                    mouseCircleRadius: 2.1,
                    ease: Power2.easeOut,
                    onUpdate: i.updateMouseCircleRadius
                })
            }), w.on("mouseleave", function() {
                TweenMax.to(i.mode, .4, {
                    mouseCircleRadius: 1.3,
                    ease: Power2.easeOut,
                    onUpdate: i.updateMouseCircleRadius
                })
            }), o.find(".content-wrapper .image").remove(), r.append(i.canvas), s = i.$canvas, o.on("showing", function() {
                i.start()
            }), o.on("entered", function() {
                i.start()
            }), o.on("hiding", function() {
                i.pause()
            }), o.on("hidden", function() {
                i.pause()
            }), o.on("opened", function() {
                i.pause()
            }), o.on("closing", function() {
                i.start()
            }), i.draw(), $window.on("resize", i.resize)), a = o.find(".detail-page"), FOLLOW_ENABLED) {
            var t = a.find(".content-wrapper.title"),
                l = t.find("h1"),
                u = t.find("ul.credits li"),
                g = a.find(".block.block-1").find("img"),
                f = a.find(".block.block-2").find(".images-mosaic img"),
                m = a.find(".block.block-3"),
                h = m.find(".bg.top"),
                p = m.find(".bg.bottom"),
                T = m.find(".description"),
                v = m.find("img"),
                S = a.find(".block.block-4"),
                E = e();
            E = (E = (E = (E = E.add(S.find("h3").first())).add(S.find(".awards li"))).add(S.find("h3").last())).add(S.find(".tweets li"));
            var w = S.find(".launch-website-btn"),
                R = [].concat(l.get(), u.get(), g.get(), f.get(), h.get(), T.get(), v.get(), p.get(), E.get(), w.get()),
                A = e(R);
            Follow.setContiguousTargets(A), f.each(function(t) {
                var n = e(this),
                    o = t - 2;
                o < 0 ? n.data("follow-target-up", g.last()) : n.data("follow-target-up", f.eq(o)), (o = t + 2) > f.length - 1 ? n.data("follow-target-down", h) : n.data("follow-target-down", f.eq(o))
            }), A.attr("follow-easing", .4), E.attr("follow-easing", .6), w.attr("follow-easing", .6), A.attr("data-follow-direction-change-mode", Follow.DIRECTION_CHANGE_MODE_PUSH), follow = new Follow("offset", FOLLOW_EFFECT_MODE), follow.ignoreTargetsBelowTop = -1200, follow.ignoreTargetsAboveTop = 1200, follow.add(A), o.on("opening-animation", follow.enable), o.on("closing", follow.disable)
        }
        $window.resize(n), $window.on("preloaded", n)
    }
}(jQuery),
function(e) {
    function t(t) {
        c = e($body.hasClass("device-phone") ? '<img src="styles/img/landing/blaze-fallback-mobile.jpg">' : '<img src="styles/img/landing/blaze.jpg">'), d = c[0], c.on("load", t)
    }

    function n() {
        r.height() > 0 && r.css("margin-top", r.height() / 2 * -1)
    }

    function o() {
        n()
    }
    var a, i, r, s, l, c, d, u = !1,
        g = {};
    PAGES.landing = g, g.preload = function(n) {
        a = e(".section-landing"), s = a.find(".background"), DEVICE_TYPE != DEVICE_TYPE_DESKTOP || IS_SAFARI_7 ? (u = !0, t(n)) : Triangles.getShadersText(function() {
            (i = new Triangles(s)).smoothingStrength = 2, i.webglSmoothingStyle = Triangles.WEBGL_SMOOTHING_STYLE_LINEAR, i.mode = e.extend({}, Triangles.PRESETS["mouse-circle-wavy"], {
                sources: ["styles/img/landing/blaze.jpg", "styles/img/landing/blaze-mask.png"],
                verticalAlign: .6,
                bitmapArea: !0,
                bitmapAreaSource: 1,
                gridPanY: !0,
                gridPanYCycleDuration: -12e3
            }), i.loadAssets(function() {
                i.init(), i.success ? n() : (u = !0, t(n))
            })
        })
    }, g.init = function() {
        r = a.find(".copy"), u ? s.append('<div class="fallback" style="background-image: url(\'' + d.src + "');\"></div>") : (s.append(i.canvas), l = i.$canvas, a.on("showing", function() {
            i.start()
        }), a.on("entered", function() {
            i.start()
        }), a.on("hiding", function() {
            i.pause()
        }), a.on("hidden", function() {
            i.pause()
        }), $window.on("resize", i.resize)), $window.resize(o), $window.on("preloaded", o), o()
    }
}(jQuery),
function(e) {
    function t() {
        n.find(".copy").height() > 0 && n.find(".copy").css("margin-top", n.find(".copy").height() / 2 * -1)
    }
    var n, o = {};
    PAGES.clients = o, o.init = function() {
        n = e(".section-clients"), $window.resize(t), $window.on("preloaded", t)
    }
}(jQuery),
function(e) {
    function t() {
        n.find(".copy").height() > 0 && n.find(".copy").css("margin-top", n.find(".copy").height() / 2 * -1 + 1)
    }
    var n, o = {};
    PAGES.awards = o, o.init = function() {
        n = e(".section-awards"), $window.resize(t), $window.on("preloaded", t)
    }
}(jQuery),
function(e) {
    function t(t) {
        c = e($body.hasClass("device-phone") ? '<img src="styles/img/triangles/about-us-mobile.jpg">' : '<img src="styles/img/triangles/about-us.jpg">'), d = c[0], c.on("load", t)
    }

    function n() {
        f && f.success && (f.resize(), f.draw()), o()
    }

    function o() {
        a.find(".copy").height() > 0 && a.find(".copy").css("margin-top", a.find(".copy").height() / 2 * -1)
    }
    var a, i, r, s, l, c, d, u, g, f, m = !1,
        h = {};
    PAGES["about-us"] = h, h.preload = function(n) {
        a = e(".section-about-us"), s = a.find(".background"), DEVICE_TYPE != DEVICE_TYPE_DESKTOP || IS_SAFARI_7 ? (m = !0, t(n)) : Triangles.getShadersText(function() {
            (i = new Triangles(s)).smoothingStrength = 2, i.webglSmoothingStyle = Triangles.WEBGL_SMOOTHING_STYLE_LINEAR, i.mode = e.extend({}, Triangles.PRESETS["mouse-circle-wavy"], {
                sources: ["styles/img/triangles/about-us.jpg", "styles/img/triangles/about-us-mask.png"],
                verticalAlign: 0,
                bitmapArea: !0,
                bitmapAreaSource: 1,
                gridPanX: !0,
                gridPanXCycleDuration: -12e4,
                gridSize: .07
            }), i.loadAssets(function() {
                i.init(), i.success ? n() : (m = !0, t(n))
            })
        })
    }, h.init = function() {
        if (r = a.find(".copy"), m ? s.append('<div class="fallback" style="background-image: url(\'' + d.src + "');\"></div>") : (s.append(i.canvas), l = i.$canvas, a.on("showing", function() {
                i.start()
            }), a.on("entered", function() {
                i.start()
            }), a.on("hiding", function() {
                i.pause()
            }), a.on("hidden", function() {
                i.pause()
            }), $window.on("resize", i.resize), i.resize(), i.draw()), u = a.find(".services-list"), g = u.find(".moon"), DEVICE_TYPE != DEVICE_TYPE_DESKTOP || IS_SAFARI_7 || (f = new Moons(g, u)).success && (u.prepend(f.canvas), f.draw(), g.find(".fallback").remove(), a.on("opening", function() {
                requestAnimationFrame(function() {
                    f.resize(), f.start()
                })
            }), a.on("closed", f.pause)), FOLLOW_ENABLED) {
            var t = a.find(".subsection"),
                o = t.filter(".services"),
                c = t.filter(".clients"),
                h = t.filter(".awards"),
                p = o.find("h2"),
                T = o.find("ul"),
                v = c.find(".bg.top"),
                S = c.find(".bg.bottom"),
                E = c.find("h2"),
                w = c.find(".clients-list").find("li"),
                R = h.find(".bg.top"),
                A = h.find("h2"),
                b = h.find("ul").find("li"),
                C = [].concat(p[0], T[0], v[0], E[0], w.get(), S[0], R[0], A[0], b.get()),
                _ = e(C);
            Follow.setContiguousTargets(_), _.attr("follow-easing", .4), w.attr("follow-easing", .7), S.attr("follow-easing", 1), R.attr("follow-easing", 1), b.attr("follow-easing", .7), _.attr("data-follow-direction-change-mode", Follow.DIRECTION_CHANGE_MODE_PUSH), follow = new Follow("offset", FOLLOW_EFFECT_MODE), follow.ignoreTargetsBelowTop = -1200, follow.ignoreTargetsAboveTop = 1200, follow.add(_), a.on("opening-animation", follow.enable), a.on("closing", follow.disable)
        }
        $window.on("resize", n), $window.on("preloaded", n), n()
    }
}(jQuery),
function(e) {
    function t(t) {
        r = e('<img class="fallback">'), s = r[0], DEVICE_TYPE == DEVICE_TYPE_PHONE ? s.src = "styles/img/contact/bg-mobile.jpg" : s.src = "styles/img/contact/bg.jpg", r.on("load", t)
    }

    function n() {}
    var o, a, i, r, s, l = !1,
        c = {};
    PAGES.contact = c;
    c.preload = function(n) {
        o = e(".section-contact"), i = o.find(".background"), DEVICE_TYPE != DEVICE_TYPE_DESKTOP || IS_SAFARI_7 ? (l = !0, t(n)) : Triangles.getShadersText(function() {
            (a = new Triangles(i)).smoothingStrength = 2, a.webglSmoothingStyle = Triangles.WEBGL_SMOOTHING_STYLE_LINEAR, a.mode = e.extend({}, Triangles.PRESETS["mouse-circle-wavy"], {
                sources: ["styles/img/contact/bg.jpg"],
                verticalAlign: -1
            }), a.loadAssets(function() {
                a.init(), a.success ? n() : (l = !0, t(n))
            })
        })
    }, c.init = function() {
        if (l) i.append('<div class="fallback" style="background-image: url(\'' + s.src + "');\"></div>");
        else {
            var e = o.find(".view-more-btn");
            e.on("mouseenter", function() {
                TweenMax.to(a.mode, .4, {
                    mouseCircleRadius: 2.1,
                    ease: Power2.easeOut,
                    onUpdate: a.updateMouseCircleRadius
                })
            }), e.on("mouseleave", function() {
                TweenMax.to(a.mode, .4, {
                    mouseCircleRadius: 1.3,
                    ease: Power2.easeOut,
                    onUpdate: a.updateMouseCircleRadius
                })
            }), i.append(a.canvas), o.on("showing", function() {
                a.start()
            }), o.on("entered", function() {
                a.start()
            }), o.on("hiding", function() {
                a.pause()
            }), o.on("hidden", function() {
                a.pause()
            }), o.on("opened", function() {
                a.pause()
            }), o.on("closing", function() {
                a.start()
            }), a.draw(), $window.on("resize", a.resize)
        }
        $window.on("preloaded", function() {
            $window.resize(n)
        })
    }
}(jQuery);
var Triangles;
! function($) {
    function getVertexShaderText(e) {
        globalVertexShaderText ? e() : $.ajax({
            url: "js/glsl/triangles/vertex.glsl.txt",
            cache: !1,
            success: function(t) {
                globalVertexShaderText = t, e()
            },
            error: function() {
                setTimeout(getVertexShaderText, 100)
            }
        })
    }

    function getFragmentShaderText(e) {
        globalFragmentShaderText ? e() : $.ajax({
            url: "js/glsl/triangles/fragment.glsl.txt",
            cache: !1,
            success: function(t) {
                globalFragmentShaderText = t, e()
            },
            error: function() {
                setTimeout(getFragmentShaderText, 100)
            }
        })
    }

    function getShadersText(e) {
        function t() {
            --n || e()
        }
        var n = 2;
        getVertexShaderText(t), getFragmentShaderText(t)
    }

    function easeIn(e, t) {
        return Math.pow(e, t)
    }

    function easeOut(e, t) {
        return 1 - Math.pow(1 - e, t)
    }

    function easeInOut(e, t) {
        return e < .5 ? easeIn(2 * e, t) / 2 : easeOut(2 * (e - .5), t) / 2 + .5
    }
    var PREVENT_ERRORS = !0,
        USER_AGENT = navigator.userAgent.toLowerCase(),
        IS_SAFARI = -1 != USER_AGENT.indexOf("safari") && -1 == USER_AGENT.indexOf("chrome"),
        PARSER_CONDITION_STRING = "// PARSER CONDITION / ",
        PARSER_CONDITION_END_STRING = "// PARSER CONDITION END",
        $window = $window,
        globalVertexShaderText, globalFragmentShaderText;
    Triangles = function($container) {
        function createCanvas() {
            $canvas = $("<canvas></canvas>"), canvas = $canvas[0], self.$canvas = $canvas, self.canvas = canvas
        }

        function getWebGLContext() {
            gl = $canvas[0].getContext("webgl", {
                premultipliedAlpha: !1
            }) || $canvas[0].getContext("experimental-webgl", {
                premultipliedAlpha: !1
            })
        }

        function init() {
            vertexShaderText = globalVertexShaderText, fragmentShaderText = globalFragmentShaderText, setPixelRatio(), parseShaderText(self.mode), shaderReplacements(), compileShaders(), setUpVertices(), getTheHandles(self.mode), setTheValues(self.mode), self.mode.texture = createTexture("texture"), updateTextures(self.mode), self.mode.bitmapArea && (self.mode.bitmapAreaTexture = createTexture("bitmapAreaTexture"), updateTexture(self.mode.bitmapAreaTexture, self.mode.loadedSources[self.mode.bitmapAreaSource])), self.mode.isJWT && (self.mode.jwtTexture = createTexture("jwtTexture"), updateTexture(self.mode.jwtTexture, self.mode.loadedSources[self.mode.jwtSource])), self.mode.isMonkey && (self.mode.monkeyTexture = createTexture("monkeyTexture"), updateTexture(self.mode.monkeyTexture, self.mode.loadedSources[self.mode.monkeySource])), self.mode.isFlatGuitars && (self.mode.flatGuitarsBgPatternTexture = createTexture("flatGuitarsBgPattern"), updateTexture(self.mode.flatGuitarsBgPatternTexture, self.mode.loadedSources[self.mode.flatGuitarsBgPatternSource])), createTextCanvas(), setUpMouseMoveHandler(), setUpVideoInteractivity(self.mode), updateDimensions(), self.success = !0
        }

        function parseShaderText(mode) {
            for (var lines = fragmentShaderText.replace(/\r\n|\n\r|\n|\r/g, "\n").split("\n"), resultText = "", conditinalsAwaitingClosure = 0, i = 0; i < lines.length; i++) {
                var line = lines[i],
                    trimmedLine = line.trim();
                if (trimmedLine.substring(0, PARSER_CONDITION_END_STRING.length) == PARSER_CONDITION_END_STRING) conditinalsAwaitingClosure && conditinalsAwaitingClosure--;
                else if (trimmedLine.substring(0, PARSER_CONDITION_STRING.length) == PARSER_CONDITION_STRING) {
                    var condition = trimmedLine.substring(PARSER_CONDITION_STRING.length);
                    !conditinalsAwaitingClosure && eval(condition) || conditinalsAwaitingClosure++
                } else conditinalsAwaitingClosure || (resultText += line + "\r\n")
            }
            fragmentShaderText = resultText
        }

        function shaderReplacements() {
            fragmentShaderText = fragmentShaderText.replace("%LEVELS%", self.mode.levels), fragmentShaderText = fragmentShaderText.replace("%FIDELITY%", toGLSLFloat(self.smoothingStrength))
        }

        function compileShaders() {
            vertexShader = compileShader(gl, vertexShaderText, gl.VERTEX_SHADER), fragmentShader = compileShader(gl, fragmentShaderText, gl.FRAGMENT_SHADER), program = createProgram(gl, vertexShader, fragmentShader), gl.useProgram(program)
        }

        function setUpVertices() {
            var e = gl.getAttribLocation(program, "position"),
                t = gl.createBuffer(),
                n = [-1, -1, 1, -1, -1, 1, -1, 1, 1, -1, 1, 1];
            gl.bindBuffer(gl.ARRAY_BUFFER, t), gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(n), gl.STATIC_DRAW), gl.enableVertexAttribArray(e), gl.vertexAttribPointer(e, 2, gl.FLOAT, !1, 0, 0)
        }

        function getTheHandles(e) {
            forceTrianglesHandle = gl.getUniformLocation(program, "forceTriangles"), trianglesOpacityHandle = gl.getUniformLocation(program, "trianglesOpacity"), maxTriangleHeightHandle = gl.getUniformLocation(program, "maxTriangleHeight"), maxTriangleHalfBaseHandle = gl.getUniformLocation(program, "maxTriangleHalfBase"), maxTriangleBaseHandle = gl.getUniformLocation(program, "maxTriangleBase"), gridPanXCycleRatioHandle = gl.getUniformLocation(program, "gridPanXCycleRatio"), gridPanYCycleRatioHandle = gl.getUniformLocation(program, "gridPanYCycleRatio"), "none" != e.gridRotationSource && (gridRotationHandle = gl.getUniformLocation(program, "gridRotation"), gridRotationCenterHandle = gl.getUniformLocation(program, "gridRotationCenter")), contrastThresholdHandle = gl.getUniformLocation(program, "contrastThreshold"), contrastIsTargetHandle = gl.getUniformLocation(program, "contrastIsTarget"), mouseCircleRadiusHandle = gl.getUniformLocation(program, "mouseCircleRadius"), mouseCircleWaveHeightRatioHandle = gl.getUniformLocation(program, "mouseCircleWaveHeightRatio"), mouseCircleWaveCyclesHandle = gl.getUniformLocation(program, "mouseCircleWaveCycles"), mouseCircleSmallWaveHeightRatioHandle = gl.getUniformLocation(program, "mouseCircleSmallWaveHeightRatio"), mouseCircleSmallWaveCyclesHandle = gl.getUniformLocation(program, "mouseCircleSmallWaveCycles"), mouseCircleWaveCycleRatioHandle = gl.getUniformLocation(program, "mouseCircleWaveCycleRatio"), timeHandle = gl.getUniformLocation(program, "time"), horizontalCropHandle = gl.getUniformLocation(program, "horizontalCrop"), verticalCropHandle = gl.getUniformLocation(program, "verticalCrop"), horizontalAlignHandle = gl.getUniformLocation(program, "horizontalAlign"), verticalAlignHandle = gl.getUniformLocation(program, "verticalAlign"), viewportAspectRatioHandle = gl.getUniformLocation(program, "viewportAspectRatio"), pointerPositionHandle = gl.getUniformLocation(program, "pointerPosition"), canvasResolutionHandle = gl.getUniformLocation(program, "canvasResolution"), pixelRatioHandle = gl.getUniformLocation(program, "pixelRatio"), e.isMonkey && (monkeyTopHandle = gl.getUniformLocation(program, "monkeyTop")), e.isFlatGuitars && (flatGuitarsBgStartLeftHandle = gl.getUniformLocation(program, "flatGuitarsBgStartLeft"), guitarTopHandle = gl.getUniformLocation(program, "guitarTop"), guitarWidthHandle = gl.getUniformLocation(program, "guitarWidth"), guitarHeightHandle = gl.getUniformLocation(program, "guitarHeight"))
        }

        function setTheValues(e) {
            gl.uniform1i(forceTrianglesHandle, e.forceTriangles), gl.uniform1f(trianglesOpacityHandle, e.trianglesOpacity), "none" != e.gridRotationSource && (gl.uniform1f(gridRotationHandle, e.gridRotation), gl.uniform2f(gridRotationCenterHandle, e.gridRotationCenterX, e.gridRotationCenterY)), gl.uniform1f(maxTriangleHeightHandle, e.gridSize), gl.uniform1f(maxTriangleHalfBaseHandle, e.gridSize / Math.tan(Math.PI / 3)), gl.uniform1f(maxTriangleBaseHandle, e.gridSize / Math.tan(Math.PI / 3) * 2), gl.uniform1f(contrastThresholdHandle, e.contrastThreshold), gl.uniform1i(contrastIsTargetHandle, e.contrastIsTarget), updateMouseCircleRadius(), gl.uniform1f(mouseCircleWaveHeightRatioHandle, e.mouseCircleWaveHeightRatio), gl.uniform1f(mouseCircleWaveCyclesHandle, e.mouseCircleWaveCycles), gl.uniform1f(mouseCircleSmallWaveHeightRatioHandle, e.mouseCircleSmallWaveHeightRatio), gl.uniform1f(mouseCircleSmallWaveCyclesHandle, e.mouseCircleSmallWaveCycles), gl.uniform1f(horizontalAlignHandle, e.horizontalAlign), gl.uniform1f(verticalAlignHandle, e.verticalAlign), e.isMonkey && updateMonkeyTop(), e.isFlatGuitars && updateFlatGuitarsDimensions()
        }

        function updateMonkeyTop() {
            gl.uniform1f(monkeyTopHandle, self.mode.monkeyTop)
        }

        function updateFlatGuitarsDimensions() {
            gl.uniform1f(flatGuitarsBgStartLeftHandle, self.mode.flatGuitarsBgStartLeft), gl.uniform1f(guitarTopHandle, self.mode.guitarTop), gl.uniform1f(guitarWidthHandle, self.mode.guitarWidth), gl.uniform1f(guitarHeightHandle, self.mode.guitarHeight)
        }

        function updateMouseCircleRadius() {
            gl.uniform1f(mouseCircleRadiusHandle, self.mode.mouseCircleRadius)
        }

        function updateTextures(e) {
            var t = getModesCurrentSourceType(e);
            "still" != t && "video" != t || updateTexture(e.texture, e.loadedSources[e.activeSource])
        }

        function createTextCanvas() {
            "text" == self.mode.sourcesType && ($textCanvas = $('<canvas class="text-source"></canvas>'), textContext = $textCanvas[0].getContext("2d"))
        }

        function updateText() {
            textContext.clearRect(0, 0, textContext.canvas.width, textContext.canvas.height), textContext.font = self.mode.textSourceFont, textContext.textAlign = self.mode.textSourceAlign, textContext.textBaseline = self.mode.textSourceBaseline, textContext.fillStyle = self.mode.textSourceColor, textContext.fillText(self.mode.sources, textContext.canvas.width / 2, textContext.canvas.height / 2), gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, $textCanvas[0])
        }

        function setUpMouseMoveHandler() {
            function e(e) {
                mouseX = (e.pageX - $container.offset().left) / viewportWidth, mouseY = (e.pageY - $container.offset().top) / viewportHeight, mouseX = 2 * mouseX - 1, mouseY = -(2 * mouseY - 1), mouseUpdated = !0
            }
            $(window).on("mousemove", e)
        }

        function setUpVideoInteractivity(e) {
            $container.on("click", function() {
                setVideosState(e, !videoPlaying), videoPlaying = !videoPlaying
            })
        }

        function setVideosState(e, t) {
            if ("video" == getModesCurrentSourceType(e)) {
                var n = e.loadedSources[e.activeSource];
                t && n.play() || n.pause()
            }
        }

        function getModesCurrentSourceType(e) {
            return "string" == typeof e.sourcesType ? e.sourcesType : e.sourcesType[e.activeSource]
        }

        function updateDimensions() {
            setPixelRatio(), setViewportSize(), setCanvasSize()
        }

        function createTexture(e) {
            var t = gl.createTexture();
            t.___textureIndex = ++textureIndex;
            var n = gl.getUniformLocation(program, e);
            gl.uniform1i(n, t.___textureIndex), gl.activeTexture(gl["TEXTURE" + t.___textureIndex]), gl.bindTexture(gl.TEXTURE_2D, t), gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE), gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
            var o = self.mode.resamplingTechnique == Triangles.NEAREST ? gl.NEAREST : gl.LINEAR;
            return gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, o), gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, o), t
        }

        function updateTexture(e, t) {
            gl.activeTexture(gl["TEXTURE" + e.___textureIndex]), gl.bindTexture(gl.TEXTURE_2D, e), gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, t)
        }

        function updateVideoTextures(e) {
            "video" == getModesCurrentSourceType(e) && updateTextures(e)
        }

        function updateMouseCircleWaveCycleRatio(e, t) {
            var n = t % e.mouseCircleWaveCycleDuration / e.mouseCircleWaveCycleDuration;
            gl.uniform1f(mouseCircleWaveCycleRatioHandle, n)
        }

        function updateGridPanXCycleRatio(e, t) {
            var n = t % e.gridPanXCycleDuration / e.gridPanXCycleDuration;
            gl.uniform1f(gridPanXCycleRatioHandle, n)
        }

        function updateGridPanYCycleRatio(e, t) {
            var n = t % e.gridPanYCycleDuration / e.gridPanYCycleDuration;
            gl.uniform1f(gridPanYCycleRatioHandle, n)
        }

        function updateGridSizeByTime(e, t) {
            if ("time" == e.gridSizeSource) {
                var n;
                if ("time" == e.gridSizeSource) {
                    var o = t % e.gridSizeCycleDuration / e.gridSizeCycleDuration,
                        a = o < .5 ? 2 * o : 2 * (1 - o);
                    a = easeInOut(a, e.gridSizeCycleEase), n = e.gridSizeMin + (e.gridSizeMax - e.gridSizeMin) * a
                } else n = e.gridSize;
                var i = n / Math.tan(Math.PI / 3),
                    r = 2 * i;
                gl.uniform1f(maxTriangleHeightHandle, n), gl.uniform1f(maxTriangleHalfBaseHandle, i), gl.uniform1f(maxTriangleBaseHandle, r)
            }
        }

        function setCanvasSize() {
            var e = "browser" == self.smoothingTechnique ? self.smoothingStrength : 1;
            pixelRatio > 1 && (e = 1);
            var t = viewportWidth * e * pixelRatio,
                n = viewportHeight * e * pixelRatio;
            IS_SAFARI && (t /= pixelRatio, n /= pixelRatio), $canvas.attr("width", t), $canvas.attr("height", n), $canvas.css({
                width: viewportWidth,
                height: viewportHeight
            });
            var o = viewportWidth / viewportHeight;
            gl.uniform1f(viewportAspectRatioHandle, o);
            var a, i, r, s;
            "still" == self.mode.sourcesType ? (r = self.mode.loadedSources[self.mode.activeSource].naturalWidth, s = self.mode.loadedSources[self.mode.activeSource].naturalHeight) : "video" == self.mode.sourcesType ? (r = self.mode.loadedSources[self.mode.activeSource].videoWidth, s = self.mode.loadedSources[self.mode.activeSource].videoHeight) : (r = t, s = n);
            var l = r / s;
            o > l ? (a = 1, i = l / o) : (i = 1, a = o / l), gl.uniform1f(horizontalCropHandle, a), gl.uniform1f(verticalCropHandle, i), gl.uniform2f(canvasResolutionHandle, t, n), gl.uniform1f(pixelRatioHandle, IS_SAFARI ? 1 : pixelRatio), gl.viewport(0, 0, t, n), "text" == self.mode.sourcesType && ($textCanvas.attr("width", t), $textCanvas.attr("height", n), $textCanvas.css({
                width: viewportWidth,
                height: viewportHeight
            }), updateText())
        }

        function drawScene() {
            updateVideoTextures(self.mode);
            var e = (new Date).getTime() - renderStartTime;
            if (gl.uniform1f(timeHandle, e), updateMouseCircleWaveCycleRatio(self.mode, e), self.mode.gridPanX && updateGridPanXCycleRatio(self.mode, e), self.mode.gridPanY && updateGridPanYCycleRatio(self.mode, e), updateGridSizeByTime(self.mode, e), "time" == self.mode.gridRotationSource) {
                var t = self.mode.gridRotationSpeed * e;
                gl.uniform1f(gridRotationHandle, t)
            }
            mouseUpdated && (gl.uniform2f(pointerPositionHandle, mouseX, mouseY), mouseUpdated = !1), gl.drawArrays(gl.TRIANGLES, 0, 6)
        }

        function doLoadAsset(e, t, n) {
            if ("still" == t) {
                var o = document.createElement("img");
                $(o).on("load", function() {
                    n(o)
                }), o.src = e
            } else(o = document.createElement("video")).autoplay = !0, o.volume = .5, $(o).on("canplaythrough", function() {
                n(o)
            }), o.src = e
        }

        function doLoadAssets(e, t) {
            function n() {
                !--o && t()
            }
            if ("text" != e.sourcesType)
                if ("string" == typeof e.sources) e.loadedSources = [], doLoadAsset(e.sources, e.sourcesType, function(n) {
                    e.loadedSources.push(n), t()
                });
                else {
                    e.loadedSources = [];
                    for (var o = e.sources.length, a = 0; a < e.sources.length; a++) ! function() {
                        var t = a,
                            o = "string" == typeof e.sourcesType ? e.sourcesType : e.sourcesType[a];
                        doLoadAsset(e.sources[a], o, function(o) {
                            e.loadedSources[t] = o, n()
                        })
                    }()
                }
            else t()
        }

        function releaseEverything() {
            $canvas = null, canvas = null, self.$canvas = null, self.canvas = null, vertexShaderText = null, fragmentShaderText = null, vertexShader = null, fragmentShader = null, program = null, nextFrame && (cancelAnimationFrame(nextFrame), nextFrame = null), self.resize = null, self.start = null, self.pause = null
        }

        function frame() {
            nextFrame = requestAnimationFrame(frame), drawScene()
        }

        function start() {
            if (!rendering) {
                if (rendering = !0, pauseStartTime) {
                    var e = (new Date).getTime() - pauseStartTime;
                    renderStartTime += e
                }
                nextFrame = requestAnimationFrame(frame)
            }
        }

        function pause() {
            rendering && (rendering = !1, pauseStartTime = (new Date).getTime(), cancelAnimationFrame(nextFrame))
        }

        function setViewportSize() {
            viewportWidth = $container.width(), viewportHeight = $container.height()
        }

        function setPixelRatio() {
            pixelRatio = 1, void 0 !== window.screen.systemXDPI && void 0 !== window.screen.logicalXDPI ? pixelRatio = window.screen.systemXDPI / window.screen.logicalXDPI : void 0 !== window.devicePixelRatio && (pixelRatio = window.devicePixelRatio)
        }

        function toGLSLFloat(e) {
            return "number" == typeof e && isFinite(e) && Math.floor(e) === e ? e + ".0" : e.toString()
        }
        var vertexShaderText, fragmentShaderText, self = this,
            viewportWidth, viewportHeight, pixelRatio, $canvas, canvas, $textCanvas, textContext, gl, vertexShader, fragmentShader, program, rendering = !1,
            renderStartTime = (new Date).getTime(),
            pauseStartTime, videoPlaying = !0,
            forceTrianglesHandle, trianglesOpacityHandle, maxTriangleHeightHandle, maxTriangleHalfBaseHandle, maxTriangleBaseHandle, gridPanXCycleRatioHandle, gridPanYCycleRatioHandle, gridRotationHandle, contrastThresholdHandle, contrastIsTargetHandle, mouseCircleRadiusHandle, mouseCircleWaveHeightRatioHandle, mouseCircleWaveCyclesHandle, mouseCircleSmallWaveHeightRatioHandle, mouseCircleSmallWaveCyclesHandle, mouseCircleWaveCycleRatioHandle, timeHandle, horizontalCropHandle, verticalCropHandle, horizontalAlignHandle, verticalAlignHandle, viewportAspectRatioHandle, pointerPositionHandle, canvasResolutionHandle, pixelRatioHandle, monkeyTopHandle, flatGuitarsBgStartLeftHandle, guitarTopHandle, guitarWidthHandle, guitarHeightHandle, nextFrame, mouseX, mouseY, mouseUpdated = !1;
        this.success = !1, this.smoothingTechnique = "webgl", this.smoothingStrength = 2, this.webglSmoothingStyle = Triangles.WEBGL_SMOOTHING_STYLE_FULL, this.init = function() {
            if (createCanvas(), PREVENT_ERRORS) try {
                getWebGLContext();
                try {
                    init()
                } catch (e) {
                    console.log("Error during initialization")
                }
            } catch (e) {
                console.log("Could not obtain webgl object")
            } else getWebGLContext(), init();
            self.success || releaseEverything()
        }, self.updateMonkeyTop = updateMonkeyTop, self.updateFlatGuitarsDimensions = updateFlatGuitarsDimensions, self.updateMouseCircleRadius = updateMouseCircleRadius, self.updateTexture = function() {
            updateTexture(self.mode.texture, self.mode.loadedSources[self.mode.activeSource])
        };
        var textureIndex = 0;
        this.loadAssets = function(e) {
            doLoadAssets(self.mode, e)
        }, this.resize = updateDimensions, this.start = start, this.pause = pause, this.draw = function() {
            var e = rendering;
            start(), drawScene(), e || pause()
        }
    }, Triangles.WEBGL_SMOOTHING_STYLE_LINEAR = 0, Triangles.WEBGL_SMOOTHING_STYLE_FULL = 1, Triangles.UNIFORM_ACTIVE_AREA = 0, Triangles.MOUSE_ACTIVE_AREA = 1, Triangles.CIRCLE_MOUSE_AREA = 0, Triangles.WAVY_CIRCLE_MOUSE_AREA = 1, Triangles.NEAREST = 0, Triangles.LINEAR = 1;
    var defaults = {
        name: null,
        resamplingTechnique: Triangles.LINEAR,
        levels: 2,
        forceTriangles: !0,
        trianglesOpacity: 1,
        overlapTriangles: !1,
        gridSizeSource: "fixed",
        gridSize: .2,
        gridSizeMin: .001,
        gridSizeMax: .3,
        gridSizeCycleDuration: 8e3,
        gridSizeCycleEase: 2.5,
        gridSizeBitmap: null,
        gridSizeInvert: !1,
        gridPanX: !1,
        gridPanXCycleDuration: 1e3,
        gridPanY: !1,
        gridPanYCycleDuration: 1e3,
        gridRotationSource: "none",
        gridRotation: 0,
        gridRotationCenterX: 0,
        gridRotationCenterY: 0,
        gridRotationSpeed: -5e-5,
        gridRotationMin: -Math.PI,
        gridRotationMax: Math.PI,
        contrastPrecision: 1,
        contastMode: "combinedChannels",
        contrastThreshold: .2,
        contrastIsTarget: !0,
        activeArea: Triangles.UNIFORM_ACTIVE_AREA,
        mouseAreaShape: Triangles.WAVY_CIRCLE_MOUSE_AREA,
        mouseCircleRadius: 1.3,
        mouseCircleWaveHeightRatio: .2,
        mouseCircleWaveCycles: 10,
        mouseCircleSmallWaveHeightRatio: .1,
        mouseCircleSmallWaveCycles: 25,
        mouseCircleWaveCycleDuration: 3e3,
        bitmapArea: !1,
        bitmapAreaSource: 0,
        invertArea: !0,
        outlineTriangles: !1,
        outlineColor: "vec4(1.0, 1.0, 1.0, .3)",
        outlineThickness: 1.5,
        sourceIsTransparent: !1,
        transparentCanvas: !1,
        sourcesType: "still",
        sources: null,
        textSourceColor: "#ffffff",
        textSourceFont: "900 150px sans-serif",
        textSourceAlign: "center",
        textSourceBaseline: "middle",
        activeSource: 0,
        bitmapMasks: null,
        horizontalAlign: 0,
        verticalAlign: 0
    };
    Triangles.PRESETS = {}, Triangles.PRESETS.default = $.extend({}, defaults, {
        name: "default",
        sources: "styles/img/triangles/5.jpg"
    }), Triangles.PRESETS["mouse-circle"] = $.extend({}, defaults, {
        name: "mouse-circle",
        levels: 4,
        gridSize: .1,
        forceTriangles: !1,
        activeArea: Triangles.MOUSE_ACTIVE_AREA,
        mouseAreaShape: Triangles.CIRCLE_MOUSE_AREA,
        invertArea: !1,
        sources: "styles/img/triangles/25.jpg"
    }), Triangles.PRESETS["mouse-circle-wavy"] = $.extend({}, defaults, {
        name: "mouse-circle-wavy",
        levels: 6,
        gridSize: .1,
        forceTriangles: !1,
        activeArea: Triangles.MOUSE_ACTIVE_AREA,
        mouseAreaShape: Triangles.WAVY_CIRCLE_MOUSE_AREA,
        invertArea: !1,
        sources: "styles/img/triangles/25.jpg"
    }), Triangles.PRESETS["mouse-circle-wavy-alive"] = $.extend({}, Triangles.PRESETS["mouse-circle-wavy"], {
        gridRotationSource: "time",
        gridRotationSpeed: -4e-5,
        gridSizeSource: "time",
        gridSizeCycleDuration: 7e3,
        gridSizeMin: .097,
        gridSizeMax: .103
    }), Triangles.PRESETS["mouse-circle-inverted"] = $.extend({}, Triangles.PRESETS["mouse-circle"], {
        name: "mouse-circle-inverted",
        mouseCircleRadius: 1.6,
        invertArea: !0
    }), Triangles.PRESETS["mouse-circle-wavy-inverted"] = $.extend({}, Triangles.PRESETS["mouse-circle-wavy"], {
        name: "mouse-circle-wavy-inverted",
        mouseCircleRadius: 1.6,
        invertArea: !0
    }), Triangles.PRESETS["mouse-circle-wavy-inverted-alive"] = $.extend({}, Triangles.PRESETS["mouse-circle-wavy-inverted"], {
        gridRotationSource: "time",
        gridRotationSpeed: -4e-5,
        gridSizeSource: "time",
        gridSizeCycleDuration: 7e3,
        gridSizeMin: .097,
        gridSizeMax: .103
    }), Triangles.PRESETS.motion = $.extend({}, defaults, {
        name: "motion",
        levels: 2,
        gridSize: .15,
        forceTriangles: !1,
        trianglesOpacity: .7,
        sources: "media/vid/1.mp4",
        sourcesType: "video"
    }), Triangles.PRESETS["motion-3"] = $.extend({}, defaults, {
        name: "motion-3",
        levels: 2,
        gridSize: .15,
        trianglesOpacity: .7,
        sources: "media/vid/1.mp4",
        sourcesType: "video"
    }), Triangles.PRESETS["grid-size-time"] = $.extend({}, defaults, {
        name: "grid-size-time",
        sources: "styles/img/triangles/9.jpg",
        gridSizeSource: "time",
        gridSizeMin: 1e-4,
        gridSizeMax: .2
    }), Triangles.PRESETS["grid-rotation"] = $.extend({}, defaults, {
        name: "grid-rotation",
        sources: "styles/img/triangles/13.jpg",
        gridRotationSource: "fixed",
        gridRotation: -Math.PI / 20
    }), Triangles.PRESETS["grid-rotation-time"] = $.extend({}, defaults, {
        name: "grid-rotation-time",
        sources: "styles/img/triangles/13.jpg",
        gridRotationSource: "time",
        gridRotationSpeed: -.03 / 1e3,
        gridSize: .15,
        levels: 2
    }), Triangles.PRESETS["grid-rotation-time-off-center"] = $.extend({}, Triangles.PRESETS["grid-rotation-time"], {
        name: "grid-rotation-time-off-center",
        gridRotationCenterX: 2,
        gridRotationCenterY: -4
    }), Triangles.PRESETS.transparency = $.extend({}, defaults, {
        name: "transparency",
        sources: "styles/img/triangles/1.png",
        gridRotationSource: "time",
        gridRotationSpeed: -3e-4,
        gridSizeSource: "time",
        gridSizeCycleDuration: 12e3,
        gridSizeMin: .01,
        gridSizeMax: .3
    }), Triangles.PRESETS.text = $.extend({}, Triangles.PRESETS.transparency, {
        name: "text",
        sourcesType: "text",
        sources: "TRUMP 2016",
        gridRotationSpeed: -1e-4,
        gridSizeMin: .001,
        gridSizeCycleDuration: 8e3
    }), Triangles.getVertexShaderText = getVertexShaderText, Triangles.getFragmentShaderText = getFragmentShaderText, Triangles.getShadersText = getShadersText
}(jQuery);
//# sourceMappingURL=main.min.js.map


*/