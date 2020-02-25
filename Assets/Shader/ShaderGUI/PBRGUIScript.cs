using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System;

public class PBRGUIScript : ShaderGUI {
    MaterialEditor editor;
    MaterialProperty[] properties;
    Material mat;
    //void drawMain() {
    
    //}
    public override void OnGUI(MaterialEditor e, MaterialProperty[] p) {
        //base.OnGUI(materialEditor, properties);
        editor = e;
        properties = p;

        mat = editor.target as Material;

        GUILayout.Label("Main", EditorStyles.boldLabel);
        EditorGUI.indentLevel++;
            MaterialProperty mainTex = FindProperty("_MainTex", properties);
            MaterialProperty color = FindProperty("_Color", properties);
            MaterialProperty specular = FindProperty("_SpecularColor", properties);
            MaterialProperty glossiness = FindProperty("_Glossiness", properties);

            GUIContent albedoLabel = new GUIContent(mainTex.displayName, "Albedo color of the material");

            editor.TexturePropertySingleLine(albedoLabel, mainTex);
            editor.TextureScaleOffsetProperty(mainTex);

            editor.ShaderProperty(color, "Diffuse");
            editor.ShaderProperty(specular, "Specular");

            editor.ShaderProperty(glossiness, MakeLabel(glossiness));

            toggleBoldKeyword("Specular", mat, "H_USE_SPECULAR");
            bool useFresnel = toggleBoldKeyword("Fresnel", mat, "H_USE_FRESNEL");
            if (useFresnel) {
                MaterialProperty reflection = FindProperty("_ReflectionCoefficient", properties);
                editor.ShaderProperty(reflection, MakeLabel(reflection));
            }
        EditorGUI.indentLevel--;

        GUILayout.Label("Details", EditorStyles.boldLabel);
        EditorGUI.indentLevel++;
            toggleKeyword("Voronoi Tiling", mat, "H_USE_VORONOI_TEXTURES");
            toggleKeyword("Vertex Color", mat, "H_USE_VERTEX_COLOR");
            toggleKeyword("Daylight Grayscale", mat, "H_USE_DAYLIGHT_GRAYSCALE");
            toggleKeyword("Cutout", mat, "H_USE_CUTOUT");

        bool useDetail = toggleBoldKeyword("Detail Texture", mat, "H_USE_DETAIL_TEXTURE");
            EditorGUI.indentLevel++;
                if (useDetail) {
                    MaterialProperty detailTex = FindProperty("_DetailTex", properties);
                    MaterialProperty detailBalance = FindProperty("_DetailBalance", properties);

                    GUIContent detailLabel = new GUIContent(detailTex.displayName, "Detail");
                    editor.TexturePropertySingleLine(detailLabel, detailTex, detailBalance);
                    editor.TextureScaleOffsetProperty(detailTex);
                }
            EditorGUI.indentLevel--;

            bool useNormal = toggleBoldKeyword("Normal Map", mat, "H_USE_NORMAL_MAP");
            EditorGUI.indentLevel++;
                if (useNormal) {
                    MaterialProperty normalTex = FindProperty("_NormalMap", properties);
                    MaterialProperty bumpiness = FindProperty("_Bumpiness", properties);

                    GUIContent normalLabel = new GUIContent(normalTex.displayName, "Normal");
                    editor.TexturePropertySingleLine(normalLabel, normalTex);
                    editor.ShaderProperty(bumpiness, MakeLabel(bumpiness));
            EditorGUI.indentLevel--;

                bool useDetailNormal = toggleBoldKeyword("Detail Normal Map", mat, "H_USE_DETAIL_NORMAL_MAP");
            EditorGUI.indentLevel++;
                if (useDetailNormal) {
                    MaterialProperty detailTex = FindProperty("_DetailNormalMap", properties);
                    MaterialProperty detailBumpiness = FindProperty("_DetailBumpiness", properties);

                    GUIContent detailLabel = new GUIContent("Detail Normal", "Detail Normal Map");
                    editor.TexturePropertySingleLine(detailLabel, detailTex);
                    editor.ShaderProperty(detailBumpiness, MakeLabel(detailBumpiness));

                    if (!useDetail) {
                        editor.TextureScaleOffsetProperty(detailTex);
                    }
                }
            EditorGUI.indentLevel--;

            }
        //bool detailTexEnabled = toggleKeyword("Enable Detail Texture", mat, "H_USE_DETAIL_TEXTURE");
        //if (detailTexEnabled) {s
        //    Texture2D image = 
        //    (Texture2D)EditorGUI.ObjectField(new Rect(3, 3, 200, 20),
        //    "Add a Texture:",
        //    image,
        //    typeof(Texture2D));
        //}

        //toggleKeyword("Detail Texture", mat, "H_USE_DETAIL_TEXTURE");
    }

    static GUIContent staticLabel = new GUIContent();
    static GUIContent MakeLabel(string text, string tooltip = null) {
        staticLabel.text = text;
        staticLabel.tooltip = tooltip;
        return staticLabel;
    }
    static GUIContent MakeLabel(MaterialProperty property, string tooltip = null) {
        staticLabel.text = property.displayName;
        staticLabel.tooltip = tooltip;
        return staticLabel;
    }

    bool toggleKeyword(String toggleName, Material mat, String keyword) {
        bool keywordSet = Array.IndexOf(mat.shaderKeywords, keyword) != -1;
        EditorGUI.BeginChangeCheck();

        // Create toggle
        keywordSet = EditorGUILayout.Toggle(toggleName, keywordSet, EditorStyles.toggle);

        if (EditorGUI.EndChangeCheck()) {
            // enable or disable the keyword based on checkbox
            if (keywordSet)
                mat.EnableKeyword(keyword);
            else
                mat.DisableKeyword(keyword);
        }
        return keywordSet;
    }

    bool toggleBoldKeyword(String toggleName, Material mat, String keyword) {
        bool keywordSet = Array.IndexOf(mat.shaderKeywords, keyword) != -1;
        EditorGUI.BeginChangeCheck();

        // Use bold label
        var origFontStyle = EditorStyles.label.fontStyle;
        EditorStyles.label.fontStyle = FontStyle.Bold;

        // Create toggle
        keywordSet = EditorGUILayout.Toggle(toggleName, keywordSet, EditorStyles.toggle);

        // Set back to normal font style
        EditorStyles.label.fontStyle = origFontStyle;

        if (EditorGUI.EndChangeCheck()) {
            // enable or disable the keyword based on checkbox
            if (keywordSet)
                mat.EnableKeyword(keyword);
            else
                mat.DisableKeyword(keyword);
        }
        return keywordSet;
    }
}