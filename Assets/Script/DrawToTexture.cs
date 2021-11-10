using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Hsinpa.Shader {
    public class DrawToTexture : MonoBehaviour
    {
        [SerializeField]
        private Camera _camera;

        [SerializeField]
        private Material targetMaterial;

        [SerializeField, Range(0, 1)]
        private float _Power = 0.1f;

        [SerializeField, Range(0, 1)]
        private float _Range = 0.1f;

        [SerializeField]
        private Color _PaintColor;

        [SerializeField]
        private UnityEngine.Shader DrawShader;

        int layerMask = 1 << 0;

        private Vector3 _mousePoint;

        public Texture2D texture;
        public RenderTexture buffer;

        private string ShaderPowerKey = "_Power";
        private string ShaderPositionKey = "_MousePosition";
        private string ShaderColorKey = "_Color";
        private string ShaderRangeKey = "_Range";

        private Material drawMaterial;

        private void Start()
        {
            drawMaterial = new Material(DrawShader);

            buffer = new RenderTexture(256, 256, 0, RenderTextureFormat.ARGBFloat);

            targetMaterial.SetTexture("_PaintTex", buffer);
        }
        private void Update()
        {
            if (Input.GetMouseButton(0))
            {
                   Vector3 diretion =( GetMouseWorldPos() - _camera.transform.position ).normalized;
                diretion.y = -diretion.y;

                //Physics.Raycast
                RaycastHit hit;
                if (Physics.Raycast( _camera.ScreenPointToRay(Input.mousePosition), out hit, 100, layerMask)) {
                    _mousePoint = hit.point;

                    //targetMaterial.SetPass(0);

                    drawMaterial.SetFloat(ShaderPowerKey, _Power);
                    drawMaterial.SetFloat(ShaderRangeKey, _Range);

                    drawMaterial.SetVector(ShaderPositionKey, hit.textureCoord);
                    drawMaterial.SetColor(ShaderColorKey, _PaintColor);

                    RenderTexture temp = RenderTexture.GetTemporary(buffer.width, buffer.height, 0, RenderTextureFormat.ARGBFloat);
                    Graphics.Blit(buffer, temp);
                    Graphics.Blit(temp, buffer, drawMaterial);
                    RenderTexture.ReleaseTemporary(temp);
                }
            }

            if (Input.GetMouseButtonUp(0))
            {
                //targetMaterial.SetFloat(ShaderPowerKey, 0);
            }
        }

        private Vector3 GetMouseWorldPos() {
            Vector2 mousePos = new Vector2();

            // Get the mouse position from Event.
            // Note that the y position from Event is inverted.
            mousePos.x = Input.mousePosition.x;
            mousePos.y = _camera.pixelHeight - Input.mousePosition.y;

            return _camera.ScreenToWorldPoint(new Vector3(mousePos.x, mousePos.y, _camera.nearClipPlane));
        }

        private void OnGUI()
        {
            GUI.DrawTexture(new Rect(0, 0, 256, 256), buffer, ScaleMode.ScaleToFit, false, 1);
        }
    }
}
