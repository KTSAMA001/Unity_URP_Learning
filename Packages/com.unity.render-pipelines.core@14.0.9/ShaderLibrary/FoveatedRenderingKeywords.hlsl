#ifndef UNITY_FOVEATED_RENDERING_KEYWORDS_INCLUDED
#define UNITY_FOVEATED_RENDERING_KEYWORDS_INCLUDED

#if (!defined(UNITY_COMPILER_DXC) && (defined(UNITY_PLATFORM_OSX) || defined(UNITY_PLATFORM_IOS))) || defined(SHADER_API_PS5)

    #if defined(SHADER_API_PS5) || defined(SHADER_API_METAL)

        #define SUPPORTS_FOVEATED_RENDERING_NON_UNIFORM_RASTER 1

        // On Metal Foveated Rendering is currently not supported with DXC
        #pragma warning (disable : 3568) // unknown pragma ignored

        #pragma never_use_dxc metal
        #pragma dynamic_branch _ _FOVEATED_RENDERING_NON_UNIFORM_RASTER

        #pragma warning (default : 3568) // restore unknown pragma ignored

    #endif

#endif

#endif // UNITY_FOVEATED_RENDERING_KEYWORDS_INCLUDED
