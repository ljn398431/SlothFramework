using System;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class SetOutline : MonoBehaviour
{
    private TextMeshProUGUI _outline;
    public Color color;
    private void Awake()
    {
        _outline = GetComponent<TextMeshProUGUI>();
    }

    public void SetColor(Color color)
    {
        CheckComponent();
        
        _outline.outlineColor = color;
        _outline.outlineWidth = 0.05f;
    }

    private void CheckComponent()
    {
        if (_outline == null)
        {
            _outline = GetComponent<TextMeshProUGUI>();
        }
    }
    
    public Color GetColor()
    {
        CheckComponent();
        return _outline.outlineColor;
    }
}
