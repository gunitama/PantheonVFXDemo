using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Projectile : MonoBehaviour
{
    [HideInInspector] public GameObject impactEffectPrefab;
    private Rigidbody rb;
    
    public Material targetMaterial;
    public string materialParameter = "_speedPower";
    public float lerpSpeed = 5f;

    void Start()
    {
        rb = GetComponent<Rigidbody>();
    }

    void Update()
    {
        if (rb != null && rb.velocity.sqrMagnitude > 0.1f)
        {
            transform.rotation = Quaternion.LookRotation(rb.velocity);
        }

        UpdateMaterialParameter();
    }

    void UpdateMaterialParameter()
    {
        if (targetMaterial == null)
            return;

        float speedPwr = Mathf.Pow(rb.velocity.sqrMagnitude, 4f); 
        
        float targetValue = speedPwr;
        float currentValue = targetMaterial.GetFloat(materialParameter);
        float newValue = Mathf.Lerp(currentValue, targetValue, Time.deltaTime * lerpSpeed);

        targetMaterial.SetFloat(materialParameter, newValue);
    }

    void OnCollisionEnter(Collision collision)
    {
        if (impactEffectPrefab)
            Instantiate(impactEffectPrefab, collision.contacts[0].point, Quaternion.identity);

        Destroy(gameObject);
    }
}